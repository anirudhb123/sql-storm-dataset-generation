WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(Score) AS TotalScore
    FROM 
        Posts
    WHERE 
        CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 5 -- Users must have more than 5 posts in the last year
),
NestedComments AS (
    SELECT 
        c.Id AS CommentId,
        c.PostId,
        c.UserId,
        c.CreationDate,
        c.Text,
        c.Score,
        COALESCE(u.DisplayName, 'Anonymous') AS UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.Score DESC) AS CommentRank
    FROM 
        Comments c
    LEFT JOIN 
        Users u ON c.UserId = u.Id
),
RecursiveCTE AS (
    SELECT
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.Text,
        1 AS Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened Posts
    UNION ALL
    SELECT
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.Text,
        Level + 1
    FROM 
        PostHistory ph
    INNER JOIN 
        RecursiveCTE r ON ph.PostId = r.PostId
    WHERE 
        r.Level < 5 -- Limiting recursion levels to avoid infinite loops
)
SELECT 
    p.Title,
    u.DisplayName AS OwnerName,
    r.TotalPosts,
    r.TotalScore,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    nt.CommentId,
    nt.Text AS CommentText,
    nt.UserDisplayName,
    nt.CreationDate AS CommentDate,
    ph.CreationDate AS HistoryDate,
    ph.Comment AS HistoryComment,
    ph.Text AS HistoryText,
    ph.Level AS HistoryLevel
FROM 
    Posts p
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    TopUsers r ON u.Id = r.OwnerUserId
LEFT JOIN 
    NestedComments nt ON p.Id = nt.PostId AND nt.CommentRank <= 3 -- Top 3 comments per post
LEFT JOIN 
    RecursiveCTE ph ON p.Id = ph.PostId
WHERE 
    p.LastActivityDate >= NOW() - INTERVAL '30 days' -- Recent posts
ORDER BY 
    p.CreationDate DESC, 
    nt.CommentRank,
    ph.Level;

