WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -2, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
UserPostStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(SUM(rp.Score), 0) AS TotalScore,
        COALESCE(SUM(rp.UpVotes) - SUM(rp.DownVotes), 0) AS NetVotes,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    GROUP BY 
        u.Id, u.DisplayName, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
)
SELECT 
    ups.DisplayName,
    ups.TotalScore,
    ups.NetVotes,
    ups.GoldBadges,
    ups.SilverBadges,
    ups.BronzeBadges
FROM 
    UserPostStats ups
WHERE 
    ups.TotalScore > (SELECT AVG(TotalScore) FROM UserPostStats)
ORDER BY 
    ups.NetVotes DESC, 
    ups.TotalScore DESC;
