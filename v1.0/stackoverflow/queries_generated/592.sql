WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS total_bounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Bounty votes
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS user_id,
        COUNT(b.Id) AS badge_count,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS gold_badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    ub.badge_count,
    ub.gold_badges,
    COALESCE(rp.total_bounty, 0) AS total_bounty,
    CASE 
        WHEN rp.Score > 10 THEN 'High Score'
        WHEN rp.Score BETWEEN 5 AND 10 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS score_category,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = rp.Id) AS comment_count
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.user_id
WHERE 
    rp.rn = 1 -- Select only the top post per user
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 10;
