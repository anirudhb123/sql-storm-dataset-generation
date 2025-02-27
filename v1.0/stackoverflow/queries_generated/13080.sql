-- Performance benchmarking query to analyze the relationships and activity of Posts, Users, and Votes
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(v.VoteCount, 0) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON p.OwnerUserId = b.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.VoteAmount, 0)) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN (
        SELECT
            OwnerUserId,
            Id,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS VoteAmount
        FROM 
            Posts
        LEFT JOIN Votes ON Posts.Id = Votes.PostId
        GROUP BY 
            OwnerUserId, Id
    ) v ON u.Id = v.OwnerUserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    us.DisplayName AS PostOwner,
    us.Reputation AS OwnerReputation,
    us.PostCount AS OwnerPostCount,
    ps.BadgeCount,
    ps.VoteCount
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.OwnerUserId = us.UserId
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC
LIMIT 100;
