
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN (
        SELECT 
            1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
            UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
LatestPostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT tc.TagName) AS TagsUsed
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        TagCounts tc ON FIND_IN_SET(tc.TagName, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1))
    INNER JOIN (
        SELECT 
            1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
            UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR  
    GROUP BY 
        p.Id, u.DisplayName
    HAVING 
        COUNT(tc.TagName) > 1  
),
HighScoringPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        TagsUsed
    FROM 
        LatestPostDetails
    WHERE 
        Score > (SELECT AVG(Score) FROM LatestPostDetails)  
)
SELECT 
    h.PostId,
    h.Title,
    h.ViewCount,
    h.Score,
    h.CreationDate,
    h.OwnerDisplayName,
    h.CommentCount,
    COUNT(DISTINCT tc.TagName) AS DistinctTagCount,
    GROUP_CONCAT(DISTINCT tc.TagName ORDER BY tc.TagName) AS TagList
FROM 
    HighScoringPosts h
LEFT JOIN 
    TagCounts tc ON FIND_IN_SET(tc.TagName, h.TagsUsed)
GROUP BY 
    h.PostId, h.Title, h.ViewCount, h.Score, h.CreationDate, h.OwnerDisplayName, h.CommentCount
ORDER BY 
    h.Score DESC, h.ViewCount DESC;
