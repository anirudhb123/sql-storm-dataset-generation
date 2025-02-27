WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.rn = 1
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.OwnerDisplayName,
    COALESCE(b.Count, 0) AS TagUsageCount,
    CASE 
        WHEN tp.Score > 10 THEN 'High Score'
        WHEN tp.Score BETWEEN 5 AND 10 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    TopPosts tp
LEFT JOIN 
    Tags t ON tp.Title LIKE '%' || t.TagName || '%'
LEFT JOIN 
    (SELECT 
         TagName, COUNT(*) AS Count 
     FROM 
         Posts p 
     JOIN 
         Tags t ON p.Tags LIKE '%' || t.TagName || '%' 
     GROUP BY 
         TagName) b ON t.TagName = b.TagName
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;

-- Adding a correlated subquery that fetches the latest badge received by each user
SELECT 
    u.DisplayName,
    (SELECT 
         b.Name 
     FROM 
         Badges b 
     WHERE 
         b.UserId = u.Id 
     ORDER BY 
         b.Date DESC 
     LIMIT 1) AS LatestBadge
FROM 
    Users u
WHERE 
    u.Reputation > 100
ORDER BY 
    u.Reputation DESC;

-- Recursive CTE to find the hierarchy of parent-child posts in a format that can be easily read
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)
SELECT 
    PostId,
    Title,
    Level
FROM 
    PostHierarchy
ORDER BY 
    Level, Title;

-- Combine the information from the previous queries using UNION
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.OwnerDisplayName,
    NULL AS LatestBadge  -- No badge information in this set
FROM 
    TopPosts tp
UNION ALL
SELECT 
    NULL AS Title,
    NULL AS Score,
    NULL AS ViewCount,
    NULL AS CommentCount,
    u.DisplayName,
    (SELECT 
         b.Name 
     FROM 
         Badges b 
     WHERE 
         b.UserId = u.Id 
     ORDER BY 
         b.Date DESC 
     LIMIT 1) AS LatestBadge
FROM 
    Users u
WHERE 
    u.Reputation > 100
ORDER BY 
    Title, Score DESC;
