WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.VoteAmount, 0)) AS TotalVotes,
        SUM(CASE WHEN p.CreationDate < NOW() - INTERVAL '1 year' THEN p.ViewCount ELSE 0 END) AS LegacyViews,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            v.UserId,
            v.PostId,
            SUM(CASE 
                WHEN vt.Name = 'UpMod' THEN 1 
                WHEN vt.Name = 'DownMod' THEN -1 
                ELSE 0 
            END) AS VoteAmount
         FROM 
            Votes v
         JOIN 
            VoteTypes vt ON v.VoteTypeId = vt.Id
         GROUP BY 
            v.UserId, v.PostId) v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeLevel
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName AS User,
    ua.PostCount,
    ua.TotalVotes,
    ua.LegacyViews,
    tp.PostId,
    tp.Title,
    tp.Score,
    ub.BadgeCount,
    ub.HighestBadgeLevel
FROM 
    UserActivity ua
LEFT JOIN 
    TopPosts tp ON ua.UserId = tp.OwnerUserId AND tp.Rank <= 5
LEFT JOIN 
    UserBadges ub ON ua.UserId = ub.UserId
WHERE 
    ua.ActivityRank <= 10
ORDER BY 
    ua.TotalVotes DESC,
    ua.PostCount DESC;
