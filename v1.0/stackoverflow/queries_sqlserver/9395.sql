
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01 12:34:56') AS DATETIME)
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 1 THEN v.Id END) AS AcceptedVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN b.Id END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN b.Id END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN b.Id END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.AcceptedVotes,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rp.Rank
FROM 
    RankedPosts rp
JOIN 
    PostVoteStats pvs ON rp.PostId = pvs.PostId
JOIN 
    Users u ON rp.OwnerDisplayName = u.DisplayName
JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC;
