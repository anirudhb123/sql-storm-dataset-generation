
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
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
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(pvc.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvc.DownVotes, 0) AS TotalDownVotes,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top 5 Post'
        ELSE 'Other Post' 
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts pvc ON rp.PostId = pvc.PostId
LEFT JOIN 
    Users u ON rp.PostId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.Rank <= 10 
    OR (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) > 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
