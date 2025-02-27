
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 END) * 100.0 / NULLIF(COUNT(v.Id), 0), 0) AS UpvotePercentage,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS tag
         FROM (SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) n
         WHERE n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
), 
PostMetrics AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        UpvotePercentage,
        Tags,
        @row_number := @row_number + 1 AS Rank
    FROM 
        RankedPosts, (SELECT @row_number := 0) AS t
    ORDER BY 
        UpvotePercentage DESC, ViewCount DESC
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.OwnerDisplayName,
    pm.CommentCount,
    pm.ViewCount,
    pm.UpvotePercentage,
    pm.Tags,
    CASE 
        WHEN pm.UpvotePercentage >= 75 THEN 'Hot'
        WHEN pm.UpvotePercentage >= 50 THEN 'Trending'
        ELSE 'Normal'
    END AS PostStatus
FROM 
    PostMetrics pm
WHERE 
    pm.Rank <= 10  
ORDER BY 
    pm.Rank;
