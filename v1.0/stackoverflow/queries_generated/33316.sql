WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        1 AS Level,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(NULLIF(p.Tags, ''), 'No Tags') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        ph.Level + 1,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(NULLIF(p.Tags, ''), 'No Tags') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 2 -- Only answers
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.Score,
    ph.CreationDate,
    ph.OwnerDisplayName,
    ph.Level,
    ph.Tags,
    COALESCE(
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = ph.PostId), 0) AS CommentCount,
    COALESCE(
        (SELECT SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) 
         FROM Votes v 
         WHERE v.PostId = ph.PostId), 0) AS UpVoteCount,
    COALESCE(
        (SELECT SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) 
         FROM Votes v 
         WHERE v.PostId = ph.PostId), 0) AS DownVoteCount
FROM 
    PostHierarchy ph
WHERE 
    ph.Level = 1
ORDER BY 
    ph.Score DESC, ph.CreationDate DESC
LIMIT 10;

WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        AVG(p.Score) AS AverageScore,
        ARRAY_AGG(DISTINCT p.Title) AS ExampleTitles
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    ts.TagName,
    ts.PostsCount,
    ts.AverageScore,
    CASE 
        WHEN ts.PostsCount = 0 THEN 'No posts found'
        ELSE 'Example titles: ' || array_to_string(ts.ExampleTitles, ', ')
    END AS Examples
FROM 
    TagStats ts
WHERE 
    ts.AverageScore IS NOT NULL
ORDER BY 
    ts.AverageScore DESC
LIMIT 10;
