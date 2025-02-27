
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount,
        (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR 
        AND p.Score IS NOT NULL
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.PostTypeId,
        rp.CreationDate,
        rp.Score,
        rp.OwnerUserId,
        rp.VoteCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
        AND rp.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = rp.PostTypeId) 
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    CASE 
        WHEN ub.BadgeCount IS NULL THEN 'No Badges'
        WHEN ub.BadgeCount >= 5 THEN 'Expert'
        WHEN ub.BadgeCount BETWEEN 1 AND 4 THEN 'Novice'
        ELSE 'Unknown'
    END AS UserExperience,
    ub.HighestBadgeClass,
    COALESCE(u.Reputation, 0) AS UserReputation,
    CASE 
        WHEN fp.CommentCount > 0 THEN 'Engaged'
        ELSE 'Silent'
    END AS UserEngagement,
    GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS RelatedTags
FROM 
    FilteredPosts fp
LEFT JOIN 
    Users u ON fp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    (SELECT Id, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', n.n), '>', -1)) AS TagName 
     FROM Posts 
     JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n 
     ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= n.n - 1) t ON fp.PostId = t.Id
GROUP BY 
    fp.PostId, fp.Title, fp.Score, ub.BadgeCount, ub.HighestBadgeClass, u.Reputation, fp.CommentCount
ORDER BY 
    fp.Score DESC, UserEngagement DESC
LIMIT 50;
