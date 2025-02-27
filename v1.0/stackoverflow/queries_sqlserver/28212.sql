
WITH TagCounts AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        value
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
        STRING_AGG(DISTINCT tc.TagName, ', ') AS TagsUsed
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        TagCounts tc ON tc.TagName IN (SELECT value FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><'))
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')  
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, u.DisplayName
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
    STRING_AGG(DISTINCT tc.TagName, ', ') AS TagList
FROM 
    HighScoringPosts h
LEFT JOIN 
    TagCounts tc ON tc.TagName IN (SELECT value FROM STRING_SPLIT(h.TagsUsed, ', '))
GROUP BY 
    h.PostId, h.Title, h.ViewCount, h.Score, h.CreationDate, h.OwnerDisplayName, h.CommentCount
ORDER BY 
    h.Score DESC, h.ViewCount DESC;
