WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
UserRankings AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounty,
        BadgeCount,
        PostCount,
        CommentCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationRank,
    rp.Title AS LatestPost,
    rp.Score AS LatestPostScore,
    rp.ViewCount AS LatestPostViews,
    ur.TotalBounty,
    ur.BadgeCount,
    ur.PostCount,
    ur.CommentCount
FROM 
    UserRankings ur
LEFT JOIN 
    RankedPosts rp ON ur.UserId = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    ur.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    ur.ReputationRank, ur.DisplayName;
