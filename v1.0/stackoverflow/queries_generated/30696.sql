WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts created in the last year
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Rank,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Comments Available'
        ELSE 'No Comments'
    END AS CommentStatus,
    COALESCE(rp.TotalBounty, 0) AS TotalBounty
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5 -- Top 5 posts per type
ORDER BY 
    rp.PostId;

-- Recursive CTE to get hierarchy of post edits
WITH RECURSIVE PostHistoryCTE AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        1 AS Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10) -- Edit Title, Edit Body, Post Closed
    UNION ALL
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        Level + 1
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryCTE ct ON ct.PostId = ph.PostId 
    WHERE 
        ph.Id > ct.Id -- Ensures we only get later edits
)

SELECT 
    p.Id AS PostId,
    p.Title,
    ph.Id AS HistoryId,
    ph.UserDisplayName,
    ph.CreationDate,
    ph.Comment,
    ph.Level
FROM 
    Posts p
LEFT JOIN 
    PostHistoryCTE ph ON p.Id = ph.PostId
WHERE 
    p.ViewCount > 100 -- Posts with more than 100 views
ORDER BY 
    p.Id, ph.Level;

-- Set operators to see differences between 'UpMod' and 'DownMod' votes
SELECT 
    PostId,
    SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Votes
GROUP BY 
    PostId
HAVING 
    SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) 
    != SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END);
