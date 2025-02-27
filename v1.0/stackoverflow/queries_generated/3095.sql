WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId
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
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CreationDate,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    COALESCE(ps.GoldBadges, 0) AS GoldBadges,
    COALESCE(ps.SilverBadges, 0) AS SilverBadges,
    COALESCE(ps.BronzeBadges, 0) AS BronzeBadges,
    CASE 
        WHEN ps.Score >= 10 THEN 'Highly Rated'
        WHEN ps.Score BETWEEN 5 AND 9 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory,
    NTILE(4) OVER (ORDER BY ps.Score DESC) AS ScoreQuartile
FROM 
    PostStatistics ps
WHERE 
    ps.CommentCount > 0
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;
