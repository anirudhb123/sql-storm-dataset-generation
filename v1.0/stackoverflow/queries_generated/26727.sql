WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.Score > 0  -- Only popular questions
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        t.TagName
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(cr.Name, ', ') AS Reasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.PostId
),
PopularTags AS (
    SELECT 
        t.TagName,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        t.TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    ts.TagName,
    ts.QuestionCount,
    ts.AvgViewCount,
    ts.AvgScore,
    cr.Reasons AS CloseReasons,
    pt.ClosedCount AS PopularTagClosedCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON ts.QuestionCount > 10  -- Consider only tags related to significant questions
LEFT JOIN 
    CloseReasons cr ON cr.PostId = rp.PostId
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY (STRING_TO_ARRAY(rp.Body, ' '))  -- Check if popular tags are mentioned in the question body
WHERE 
    rp.PostRank <= 5  -- Get top 5 recent questions per user
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC;
