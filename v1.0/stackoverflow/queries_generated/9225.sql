WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AnswerCount,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only questions
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.AnswerCount,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    ub.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = ub.UserId)
WHERE 
    rp.Rank <= 5 -- Select top 5 posts for each user
ORDER BY 
    rp.OwnerDisplayName, rp.Score DESC;
