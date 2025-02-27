WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.ParentId, 
        1 AS Level
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
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputationSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN vh.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN vh.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END), 0) AS PositiveScorePosts,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes vh ON vh.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostCloseReasons AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        CloseReasonTypes c ON ph.Comment::INTEGER = c.Id
    WHERE 
        pht.Name = 'Post Closed'
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.Upvotes,
    u.Downvotes,
    u.ReputationRank,
    p.Title,
    ph.CloseCount,
    COALESCE(pr.CloseReasons, 'None') AS CloseReasons,
    RANK() OVER (PARTITION BY u.UserId ORDER BY p.ViewCount DESC) AS PostRank
FROM 
    UserReputationSummary u
JOIN 
    Posts p ON p.OwnerUserId = u.UserId
LEFT JOIN 
    PostCloseReasons ph ON ph.PostId = p.Id
WHERE 
    u.ReputationRank <= 10
ORDER BY 
    u.ReputationRank, p.ViewCount DESC;
