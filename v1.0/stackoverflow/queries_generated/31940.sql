WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Starting point for root posts
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,  -- Treating VoteTypeId 2 as Upvotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes,  -- Treating VoteTypeId 3 as Downvotes
        ROW_NUMBER() OVER (PARTITION BY rph.ParentId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        RecursivePostHierarchy rph ON p.Id = rph.Id OR p.ParentId = rph.Id
    GROUP BY 
        p.Id, rph.ParentId, p.Title, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.Score,
        ps.CommentCount,
        ps.Upvotes,
        ps.Downvotes
    FROM 
        PostStats ps
    WHERE 
        ps.Rank = 1  -- Selecting only top-ranked posts
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.Upvotes,
    ps.Downvotes,
    CASE 
        WHEN ps.Upvotes > ps.Downvotes THEN 'Positive'
        WHEN ps.Upvotes < ps.Downvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    CASE 
        WHEN ps.ViewCount IS NULL THEN 'No Views' 
        WHEN ps.ViewCount < 100 THEN 'Low Engagement' 
        WHEN ps.ViewCount BETWEEN 100 AND 1000 THEN 'Moderate Engagement' 
        ELSE 'High Engagement' 
    END AS EngagementLevel
FROM 
    TopPosts ps
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC;
