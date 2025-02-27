WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByRecency
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
TagStatistics AS (
    SELECT 
        TAG.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.AnswerCount) AS AvgAnswerCount
    FROM 
        Posts p
    CROSS APPLY (
        SELECT 
            TRIM(value) AS TagName
        FROM 
            STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')
    ) AS TAG
    GROUP BY 
        TAG.TagName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseEvents,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 52 THEN 1 END) AS HotQuestions,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteEvents
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.PostType,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.Owner,
    ts.PostCount AS TagPostCount,
    ts.AvgViewCount AS TagAvgViewCount,
    ts.AvgAnswerCount AS TagAvgAnswerCount,
    phs.CloseEvents,
    phs.HotQuestions,
    phs.DeleteUndeleteEvents
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON ts.PostCount > 0 -- Only include tags with posts
LEFT JOIN 
    PostHistorySummary phs ON phs.PostId = rp.PostId
WHERE 
    rp.RankByViews <= 10
ORDER BY 
    rp.RankByViews, rp.CreationDate DESC;
