
WITH TagCounts AS (
    SELECT 
        TRIM(tag) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        (SELECT 
            TRIM(unnest(split(REPLACE(substring(Tags, 2, length(Tags) - 2), '><', '>')))) AS tag
         FROM Posts
         WHERE PostTypeId = 1) AS Tags
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
        ARRAY_AGG(DISTINCT tc.TagName) AS TagsUsed
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        TagCounts tc ON tc.TagName IN (SELECT TRIM(tag) FROM TABLE(FLATTEN(INPUT => SPLIT(REPLACE(substring(p.Tags, 2, length(p.Tags) - 2), '><', '>')))))
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')  
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
    LISTAGG(DISTINCT tc.TagName, ', ') AS TagList
FROM 
    HighScoringPosts h
LEFT JOIN 
    TagCounts tc ON tc.TagName IN (SELECT TRIM(tag) FROM TABLE(FLATTEN(INPUT => SPLIT(h.TagsUsed))))
GROUP BY 
    h.PostId, h.Title, h.ViewCount, h.Score, h.CreationDate, h.OwnerDisplayName, h.CommentCount
ORDER BY 
    h.Score DESC, h.ViewCount DESC;
