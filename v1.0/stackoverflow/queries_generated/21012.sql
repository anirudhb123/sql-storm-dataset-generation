WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount,
        p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > (NOW() - INTERVAL '2 years')
),
PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(LOWER(rp.Tags), '>,<')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.ViewCount > 50
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.Title,
    rp.OwnerUserId,
    u.DisplayName AS Author,
    rp.CreatedDate,
    rp.ViewCount,
    rp.Score,
    CASE
        WHEN rp.Score > 10 THEN 'High'
        WHEN rp.Score BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS PostScoreCategory,
    pt.Tag,
    ur.Reputation,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON ur.UserId = u.Id
LEFT JOIN 
    PopularTags pt ON LOWER(pt.Tag) IN (SELECT UNNEST(STRING_TO_ARRAY(LOWER(rp.Tags), '>,<')))
WHERE 
    rp.PostRank = 1
    AND (ur.Reputation > 100 OR ur.GoldBadges > 0)
ORDER BY 
    rp.Score DESC, rp.ViewCount ASC, ur.Reputation DESC
LIMIT 100;
