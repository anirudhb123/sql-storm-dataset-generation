
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, CAST('2024-10-01 12:34:56' AS datetime))
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 
                 WHEN vt.Name = 'DownMod' THEN -1 
                 ELSE 0 END) AS VoteScore
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(pv.VoteScore, 0) AS PostVoteScore,
    rp.RankScore
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = ub.UserId)
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
WHERE 
    rp.RankScore <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
