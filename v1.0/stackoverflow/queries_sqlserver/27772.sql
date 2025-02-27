
WITH StringProcessing AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ph.Text
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
        AND p.CreationDate >= CAST('2024-10-01' AS DATE) - DATEADD(YEAR, 1, 0)
),
TagAnalysis AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS UsageCount
    FROM 
        StringProcessing
    CROSS APPLY STRING_SPLIT(Tags, '><')
    GROUP BY 
        value
),
RecentComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    WHERE 
        CreationDate >= CAST('2024-10-01' AS DATE) - DATEADD(MONTH, 1, 0)
    GROUP BY 
        PostId
),
Engagement AS (
    SELECT 
        sp.PostId,
        sp.Title,
        sp.Body,
        sp.Tags,
        COALESCE(rc.CommentCount, 0) AS CommentCount,
        ta.UsageCount AS TagUsageCount
    FROM 
        StringProcessing sp
    LEFT JOIN 
        RecentComments rc ON sp.PostId = rc.PostId
    LEFT JOIN 
        TagAnalysis ta ON ta.Tag = STRING_SPLIT(sp.Tags, '><').value
),
Ranking AS (
    SELECT 
        *,
        (CommentCount * 0.6 + TagUsageCount * 0.4) AS EngagementScore
    FROM 
        Engagement
)
SELECT 
    PostId,
    Title,
    Body,
    Tags,
    CommentCount,
    TagUsageCount,
    EngagementScore
FROM 
    Ranking
ORDER BY 
    EngagementScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
