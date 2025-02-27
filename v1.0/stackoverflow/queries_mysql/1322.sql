
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        @rn := IF(@prev = p.OwnerUserId, @rn + 1, 1) AS RN,
        GROUP_CONCAT(DISTINCT SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2)) AS UniqueTags,
        @prev := p.OwnerUserId
    FROM 
        Posts p
    CROSS JOIN (SELECT @rn := 0, @prev := NULL) AS vars
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
), UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        SUM(b.Class) AS TotalBadgeClasses
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    up.Id AS UserId,
    up.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(ubc.GoldBadges, 0) AS GoldBadges,
    COALESCE(ubc.SilverBadges, 0) AS SilverBadges,
    COALESCE(ubc.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    rp.UniqueTags
FROM 
    Users up
JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN 
    UserBadgeCounts ubc ON up.Id = ubc.UserId
LEFT JOIN 
    PostVoteStats pvs ON rp.PostId = pvs.PostId
WHERE 
    rp.RN = 1
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC;
