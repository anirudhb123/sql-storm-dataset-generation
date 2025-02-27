WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ps.UserId,
        ps.TotalBadges,
        ps.TotalPosts,
        ps.Upvotes,
        ps.Downvotes
    FROM 
        Posts p
    JOIN 
        UserReputation ps ON p.OwnerUserId = ps.UserId
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
)
SELECT 
    ps.UserId,
    ps.DisplayName,
    COUNT(ps.PostId) AS PostsCount,
    AVG(ps.Score) AS AverageScore,
    SUM(ps.Upvotes) - SUM(ps.Downvotes) AS NetVotes,
    MAX(ps.CreationDate) AS LastPostDate
FROM 
    PostStats ps
GROUP BY 
    ps.UserId, ps.DisplayName
HAVING 
    COUNT(ps.PostId) > 5
ORDER BY 
    NetVotes DESC, AverageScore DESC;
