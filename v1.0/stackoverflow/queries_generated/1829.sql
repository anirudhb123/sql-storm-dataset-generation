WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Score
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
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
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    COALESCE(rp.PostCount, 0) AS ActivePostCount,
    COALESCE(ru.TotalPosts, 0) AS TotalPosts,
    ru.GoldBadges + ru.SilverBadges * 0.5 + ru.BronzeBadges * 0.25 AS BadgeScore,
    SUM(CASE WHEN rp.PostRank <= 3 THEN 1 ELSE 0 END) AS TopPostsCount
FROM 
    ActiveUsers ru
LEFT JOIN 
    (SELECT 
        PostId, 
        COUNT(*) AS PostCount 
     FROM 
        RecentPosts 
     GROUP BY 
        PostId) rp ON ru.UserId = rp.UserId
GROUP BY 
    ru.UserId, ru.DisplayName, ru.TotalPosts, ru.GoldBadges, ru.SilverBadges, ru.BronzeBadges
HAVING 
    COALESCE(ru.TotalPosts, 0) > 0
ORDER BY 
    BadgeScore DESC, ActivePostCount DESC
LIMIT 50;
