WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        0 AS Level,
        CAST(p.Title AS VARCHAR(500)) AS HierarchyPath
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Start with top-level posts (Questions)
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        r.Level + 1,
        CAST(r.HierarchyPath || ' -> ' || p.Title AS VARCHAR(500))
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId  -- Get answers to each question
),

PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(c.Id) AS CommentCount,
        COUNT(h.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- Bounty votes
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),

UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM 
        Users u
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.TotalBounty,
    ps.CommentCount,
    ps.HistoryCount,
    u.DisplayName AS PostOwnerName,
    u.Reputation AS OwnerReputation,
    ur.ReputationCategory,
    rh.HierarchyPath
FROM 
    PostStatistics ps
JOIN 
    Users u ON ps.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation ur ON u.Id = ur.Id
LEFT JOIN 
    RecursivePostHierarchy rh ON ps.PostId = rh.PostId
WHERE 
    ps.TotalBounty > 0  -- Filter only posts with bounties
ORDER BY 
    ps.TotalBounty DESC, 
    ps.CommentCount DESC;

This query encompasses the following constructs:
- A **recursive CTE** to build a hierarchy of posts, allowing tracking of questions and their respective answers.
- A **CTE** to aggregate post statistics, capturing the total bounty, comment count, and history count.
- A **CTE** to categorize user reputations based on their scores, providing additional user context.
- The **main SELECT** query combines results from various CTEs, applying **JOINs** to aggregate data about posts and their owners, filtering results to only include posts with bounties.
- The result set is **ordered** by bounty amounts and comment counts in descending order, highlighting the most valuable posts.
