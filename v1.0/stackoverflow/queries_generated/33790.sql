WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        p.ParentId AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.Id = rp.PostId AND p.ParentId IS NOT NULL
)
, UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
    GROUP BY 
        u.Id
)
, ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.UserDisplayName AS ClosedBy,
        ph.CreationDate AS ClosedDate,
        DATEDIFF(NOW(), ph.CreationDate) AS DaysClosed
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId = 10
)
SELECT 
    rp.Title,
    rp.CreationDate AS QuestionDate,
    rp.Score AS QuestionScore,
    rp.ViewCount AS QuestionViews,
    us.DisplayName AS OwnerDisplayName,
    us.TotalBounty,
    us.TotalPosts,
    cp.ClosedBy,
    cp.ClosedDate,
    cp.DaysClosed
FROM 
    RecursivePosts rp
LEFT JOIN 
    UserScores us ON rp.OwnerUserId = us.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Level = 1 -- Only top-level questions
    AND (rp.Score > 10 OR cp.DaysClosed > 30) -- Filter: high score or closed for more than 30 days
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
