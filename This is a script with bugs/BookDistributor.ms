-- BookDistributor.ms
-- 用于在 3ds Max 2024 中自动分布书籍到书架的 MAXScript 脚本
-- 支持书籍分类、基于样条线的分布、预览和样式调整

try(destroyDialog BookDistributor) catch()

rollout BookDistributor "书籍分布器" width:300 height:650
(
    -- 用户界面元素
    group "书籍选择与分类"
    (
        pickButton btnPickBooks "选择书籍" width:140
        button btnClearBooks "清除书籍" width:140
        checkBox chkExcludeBlack "排除黑色书籍" checked:true
        listBox lbBooks "已选书籍" height:5
        label lblBookCount "书籍数量: 0" align:#left
    )
    
    group "书柜与分布区域"
    (
        pickButton btnPickShelf "选择书柜" width:140
        label lblShelfName "未选择书柜" align:#left
        pickButton btnPickSpline "选择分布样条线" width:140
        label lblSplineName "未选择样条线" align:#left
        spinner spnScale "区域缩放: " range:[0.1, 10, 1] type:#float
    )
    
    group "分布设置"
    (
        checkBox chkAlignAxis "对齐书籍轴向" checked:true
        spinner spnTilt "倾斜角度: " range:[-45, 45, 0] type:#float
        checkBox chkRandomTilt "随机倾斜" checked:false
        spinner spnRandomTiltRange "随机倾斜范围: " range:[0, 30, 10] type:#float enabled:false
        checkBox chkLayFlat "平躺摆放" checked:false
        checkBox chkFlipCover "翻转封面" checked:false
        checkBox chkAlignBottom "底部对齐书架" checked:true
        spinner spnGroupOffset "书籍组偏移: " range:[0, 100, 10] type:#float
    )
    
    group "预览与确认"
    (
        button btnPreview "预览分布" width:140
        button btnConfirm "确认并转换为模型" width:140
    )
    
    -- 变量定义
    local bookObjects = #() -- 存储书籍对象
    local shelfObject = undefined -- 书柜对象
    local splineObject = undefined -- 样条线对象
    local previewInstances = #() -- 预览实例数组
    local cachedSplineLength = 0 -- 缓存样条线长度
    
    -- 过滤黑色书籍的函数
    fn filterBooks objs excludeBlack =
    (
        filtered = #()
        for obj in objs do
        (
            if isValidNode obj then
            (
                if excludeBlack then
                (
                    mat = obj.material
                    if mat != undefined and mat.diffuse != undefined and mat.diffuse != black then
                    (
                        append filtered obj
                    )
                    else
                    (
                        print ("过滤掉对象: " + obj.name + "（材质无效或为黑色）")
                    )
                )
                else
                (
                    append filtered obj
                )
            )
            else
            (
                print ("无效对象: " + obj.name)
            )
        )
        filtered
    )
    
    -- 更新界面书籍列表的函数
    fn updateBookList =
    (
        lbBooks.items = for obj in bookObjects collect obj.name
        lblBookCount.text = "书籍数量: " + bookObjects.count as string
        if bookObjects.count == 0 then
        (
            print "警告：bookObjects 数组为空，未能添加书籍到列表"
        )
    )
    
    -- 更新书柜和样条线名称显示
    fn updateSelectionLabels =
    (
        lblShelfName.text = if shelfObject != undefined then shelfObject.name else "未选择书柜"
        lblSplineName.text = if splineObject != undefined then splineObject.name else "未选择样条线"
    )
    
    -- 计算样条线长度
    fn getCachedSplineLength spline =
    (
        if spline != undefined then
        (
            splineLength = getSegLengths spline 1
            cachedSplineLength = splineLength[splineLength.count]
        )
        cachedSplineLength
    )
    
    -- 沿样条线分布书籍的函数
    fn distributeBooks previewMode =
    (
        if splineObject == undefined or bookObjects.count == 0 then
        (
            messageBox "请先选择样条线和书籍！" title:"错误"
            return false
        )
        
        -- 检查样条线长度
        totalLength = getCachedSplineLength splineObject
        if totalLength <= 0 then
        (
            messageBox "样条线长度无效！" title:"错误"
            return false
        )
        
        -- 清除之前的预览实例
        if previewMode then
        (
            for inst in previewInstances do delete inst
            previewInstances = #()
        )
        
        -- 计算间距
        numBooks = bookObjects.count
        spacing = totalLength / (numBooks + 1)
        
        -- 分布书籍
        for i = 1 to numBooks do
        (
            book = bookObjects[i]
            pos = pathInterp splineObject 1 (i * spacing / totalLength)
            rot = quat 0 0 0 1 -- 默认旋转
            
            -- 对齐书籍轴向
            if chkAlignAxis.checked then
            (
                rot = book.rotation
            )
            
            -- 应用倾斜角度
            tiltAngle = if chkRandomTilt.checked then (random -spnRandomTiltRange.value spnRandomTiltRange.value) else spnTilt.value
            if tiltAngle != 0 then
            (
                rot = rot * (eulerToQuat (eulerAngles 0 0 tiltAngle))
            )
            
            -- 平躺摆放
            if chkLayFlat.checked then
            (
                rot = rot * (eulerToQuat (eulerAngles 90 0 0))
            )
            
            -- 翻转封面
            if chkFlipCover.checked then
            (
                rot = rot * (eulerToQuat (eulerAngles 0 180 0))
            )
            
            -- 底部对齐书架
            if chkAlignBottom.checked and shelfObject != undefined then
            (
                pos.z = shelfObject.min.z + (book.max.z - book.min.z)
            )
            
            -- 创建书籍实例
            inst = instance book pos:pos rotation:rot
            inst.pos += [0, 0, spnGroupOffset.value] -- 应用书籍组偏移
            append previewInstances inst
        )
        true
    )
    
    -- 选择书籍的事件
    on btnPickBooks picked obj do
    (
        if obj != undefined then
        (
            local selectedObjects = selection as array
            if selectedObjects.count > 0 then
            (
                bookObjects = filterBooks selectedObjects chkExcludeBlack.checked
                print ("选择了 " + selectedObjects.count as string + " 个对象，过滤后剩余 " + bookObjects.count as string + " 个")
                updateBookList()
            )
            else
            (
                print "未选择任何对象，请在场景中选择书籍后再点击"
                messageBox "请先在场景中选择书籍！" title:"错误"
            )
        )
    )
    
    -- 清除书籍的事件
    on btnClearBooks pressed do
    (
        bookObjects = #()
        updateBookList()
    )
    
    -- 选择书柜的事件
    on btnPickShelf picked obj do
    (
        shelfObject = obj
        updateSelectionLabels()
    )
    
    -- 选择样条线的事件
    on btnPickSpline picked obj do
    (
        if (classOf obj == SplineShape or classOf obj == Line) then
        (
            splineObject = obj
            splineObject.scale = [spnScale.value, spnScale.value, spnScale.value]
            updateSelectionLabels()
        )
        else
        (
            messageBox "请选择样条线！" title:"错误"
        )
    )
    
    -- 调整样条线缩放的事件
    on spnScale changed val do
    (
        if splineObject != undefined then
        (
            splineObject.scale = [val, val, val]
            if previewInstances.count > 0 then distributeBooks true
        )
    )
    
    -- 随机倾斜开关事件
    on chkRandomTilt changed state do
    (
        spnRandomTiltRange.enabled = state
        spnTilt.enabled = not state
    )
    
    -- 预览分布的事件
    on btnPreview pressed do
    (
        distributeBooks true
    )
    
    -- 确认并转换为模型的事件
    on btnConfirm pressed do
    (
        if previewInstances.count > 0 then
        (
            for inst in previewInstances do convertTo inst Editable_Mesh
            previewInstances = #()
            messageBox "书籍已转换为模型！" title:"成功"
        )
        else
        (
            messageBox "没有可转换的书籍！" title:"错误"
        )
    )
    
    -- 对话框关闭时清理
    on BookDistributor close do
    (
        for inst in previewInstances do delete inst
        previewInstances = #()
    )
)

-- 创建对话框
createDialog BookDistributor