WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.Reputation AS UserReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- counting only upvotes and downvotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, u.Reputation
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(rp.PostCount, 0) AS PostCount,
        COALESCE(rp.VoteCount, 0) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN (
        SELECT 
            OwnerUserId, 
            COUNT(Id) AS PostCount, 
            SUM(VoteCount) AS VoteCount
        FROM 
            RankedPosts
        GROUP BY 
            OwnerUserId
    ) rp ON u.Id = rp.OwnerUserId
)

SELECT 
    us.DisplayName,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.PostCount,
    us.TotalVotes,
    RANK() OVER (ORDER BY us.TotalVotes DESC) AS OverallRank  
FROM 
    UserStats us
WHERE 
    us.PostCount > 0
ORDER BY 
    OverallRank
LIMIT 10;


This SQL query performs a comprehensive analysis of users and their posts on a "Stack Overflow" style platform. 

1. **RankedPosts CTE**: This Common Table Expression aggregates the posts by counting the votes and ranks them for each user based on post creation date within the last year.

2. **UserBadges CTE**: This CTE calculates the number of gold, silver, and bronze badges per user.

3. **UserStats CTE**: This collects user details and integrates badge counts with the ranked posts aggregation to show total votes and post counts.

4. **Final SELECT**: The main query returns data for users with at least one post, ranking them by their total votes. 

This query utilizes constructs like CTEs, aggregates, window functions, and join operations to present a detailed performance benchmark, allowing for efficiency checks and powerful insights into user engagement over time.
