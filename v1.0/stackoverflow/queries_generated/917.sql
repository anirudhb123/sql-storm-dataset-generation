WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
), UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COALESCE(SUM(p.Score), 0) AS TotalPostScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), PopularUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPostScore,
        us.TotalPosts,
        us.TotalBadges,
        RANK() OVER (ORDER BY us.TotalPostScore DESC, us.Reputation DESC) AS UserPopularityRank
    FROM 
        UserStatistics us
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    u.DisplayName AS Author,
    u.Reputation AS AuthorReputation,
    p.CommentCount,
    CASE 
        WHEN p.PostRank = 1 THEN 'Most Recent Post'
        WHEN p.PostRank <= 3 THEN 'Top 3 Posts'
        ELSE NULL 
    END AS PostCategory,
    pu.UserPopularityRank
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PopularUsers pu ON u.Id = pu.UserId
WHERE 
    pu.UserPopularityRank IS NOT NULL
ORDER BY 
    pu.UserPopularityRank ASC, p.CreationDate DESC;
