
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        @row_number := IF(@prev_owner = p.OwnerUserId, @row_number + 1, 1) AS rnk,
        @prev_owner := p.OwnerUserId
    FROM 
        Posts p, (SELECT @row_number := 0, @prev_owner := NULL) AS vars
    WHERE 
        p.Score > 0
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 1
),
UserBadges AS (
    SELECT 
        b.UserId,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        v.CreationDate,
        vt.Name AS VoteType,
        @row_number_v := IF(@prev_post = v.PostId, @row_number_v + 1, 1) AS rnk,
        @prev_post := v.PostId
    FROM 
        Votes v, VoteTypes vt, (SELECT @row_number_v := 0, @prev_post := NULL) AS vars
    WHERE 
        v.VoteTypeId = vt.Id AND v.CreationDate >= CURDATE() - INTERVAL 30 DAY
    ORDER BY 
        v.PostId, v.CreationDate DESC
)
SELECT 
    u.DisplayName,
    COALESCE(up.PostCount, 0) AS TotalPosts,
    COALESCE(up.TotalViews, 0) AS TotalViews,
    COALESCE(ub.BadgeNames, 'No Badges') AS Badges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rv.VoteType
FROM 
    Users u
LEFT JOIN 
    TopUsers up ON u.Id = up.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.rnk = 1
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId AND rv.rnk = 1
WHERE 
    u.Reputation > 1000
ORDER BY 
    up.TotalViews DESC, 
    u.DisplayName;
