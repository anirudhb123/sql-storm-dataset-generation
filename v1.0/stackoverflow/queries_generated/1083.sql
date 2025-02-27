WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT CASE WHEN pt.Name = 'Answer' THEN p2.Id END) AS TotalAnswers,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- Only consider BountyStart and BountyClose
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts p2 ON p.Id = p2.ParentId AND p2.PostTypeId = 2
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    ps.Title AS PostTitle,
    ps.TotalBounty,
    ps.TotalComments,
    ps.TotalAnswers,
    ps.RecentPostRank
FROM 
    Users u
LEFT JOIN 
    UserBadges us ON u.Id = us.UserId
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
WHERE 
    u.Reputation > 1000
    AND (us.GoldBadges > 0 OR us.SilverBadges > 2 OR ps.TotalAnswers > 5)
    AND ps.RecentPostRank <= 3
ORDER BY 
    us.GoldBadges DESC,
    ps.TotalBounty DESC,
    ps.TotalComments DESC;
