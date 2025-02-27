WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
LatestPosts AS (
    SELECT 
        OwnerUserId,
        MAX(CreationDate) AS LastActiveDate
    FROM 
        RecursiveCTE
    GROUP BY 
        OwnerUserId
),
ActiveUserSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(r.CommentCount, 0) AS TotalComments,
        COALESCE(r.Upvotes - r.Downvotes, 0) AS NetVotes,
        lp.LastActiveDate
    FROM 
        Users u
        LEFT JOIN RecursiveCTE r ON u.Id = r.OwnerUserId
        JOIN LatestPosts lp ON u.Id = lp.OwnerUserId
)
SELECT 
    a.DisplayName,
    a.TotalComments,
    a.NetVotes,
    CASE 
        WHEN a.LastActiveDate > NOW() - INTERVAL '30 days' THEN 'Active'
        ELSE 'Inactive'
    END AS UserStatus
FROM 
    ActiveUserSummary a
WHERE 
    a.NetVotes >= 0 
ORDER BY 
    a.TotalComments DESC 
LIMIT 10;

-- Additional benchmarking operations:
SELECT 
    COUNT(*) AS TotalPosts,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
    AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgResponseTime
FROM 
    Posts p
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year';
