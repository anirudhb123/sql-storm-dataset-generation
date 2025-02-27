-- Performance Benchmarking Query on StackOverflow Schema

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        AVG(CASE WHEN p.OwnerUserId IS NOT NULL THEN p.Score ELSE NULL END) AS AvgPostScore,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.AvgPostScore,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.UserId = ps.PostId -- Join condition can be modified based on requirements
ORDER BY 
    us.AvgPostScore DESC, 
    ps.Score DESC;
