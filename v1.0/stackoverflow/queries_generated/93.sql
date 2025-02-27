WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT c.Id) DESC) AS PopularityRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 500
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.DisplayName,
    ps.Title,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    us.TotalPosts,
    (us.GoldBadges + us.SilverBadges + us.BronzeBadges) AS TotalBadges,
    ps.PopularityRank,
    CASE 
        WHEN us.TotalPosts IS NULL THEN 'New User' 
        ELSE 'Active User' 
    END AS UserType
FROM 
    PostStats ps
FULL OUTER JOIN 
    UserStats us ON ps.PostId = us.UserId
WHERE 
    ps.RecentPostRank <= 5 OR us.TotalPosts IS NOT NULL
ORDER BY 
    COALESCE(ps.PopularityRank, 9999), us.TotalPosts DESC NULLS LAST
LIMIT 100;
