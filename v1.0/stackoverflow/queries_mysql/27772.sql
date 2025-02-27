
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
        AND p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR) 
),
TagAnalysis AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS Tag,
        COUNT(*) AS UsageCount
    FROM 
        StringProcessing
    INNER JOIN (
        SELECT 
            a.N + b.N * 10 + 1 n
        FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    GROUP BY 
        Tag
),
RecentComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    WHERE 
        CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 MONTH) 
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
        TagAnalysis ta ON ta.Tag = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(sp.Tags, '><', n.n), '><', -1))
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
LIMIT 10;
