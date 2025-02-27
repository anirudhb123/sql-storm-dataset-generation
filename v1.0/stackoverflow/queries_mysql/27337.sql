
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),
TagAnalysis AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        pt.Name AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name IN ('Post Closed', 'Post Reopened')
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Owner,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    ta.TagName,
    ta.TagCount,
    cp.CreationDate AS ClosedDate,
    cp.UserDisplayName AS ClosedBy,
    cp.Comment AS ClosureComment,
    cp.PostHistoryType AS ClosureType
FROM 
    RankedPosts rp
LEFT JOIN 
    TagAnalysis ta ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE CONCAT('%', ta.TagName, '%'))
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.RankByScore <= 5  
GROUP BY 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Owner,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    ta.TagName,
    ta.TagCount,
    cp.CreationDate,
    cp.UserDisplayName,
    cp.Comment,
    cp.PostHistoryType
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC;
