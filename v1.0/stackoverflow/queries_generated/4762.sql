WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Level,
    u.DisplayName AS OwnerDisplayName,
    u.TotalPosts,
    u.TotalScore,
    COALESCE(v.Upvotes, 0) AS Upvotes,
    COALESCE(v.Downvotes, 0) AS Downvotes,
    v.TotalBounty,
    CASE
        WHEN r.ParentId IS NOT NULL THEN
            (SELECT COUNT(*) 
             FROM Posts p2 
             WHERE p2.ParentId = r.PostId)
        ELSE 0 
    END AS ChildPostCount
FROM 
    RecursivePostHierarchy r
LEFT JOIN 
    UserPosts u ON r.OwnerUserId = u.UserId
LEFT JOIN 
    PostVoteStats v ON r.PostId = v.PostId
WHERE 
    (u.TotalPosts > 5 OR v.Upvotes > 10)
ORDER BY 
    r.CreationDate DESC, u.TotalScore DESC
FETCH FIRST 100 ROWS ONLY;
