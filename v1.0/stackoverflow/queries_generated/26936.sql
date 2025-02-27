WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(trim(both '<>' from Tags), '><')) AS TagName,
        COUNT(*) AS Count
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        TagName
),
UserBadgeSummary AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
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
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    ts.Count AS TagCount,
    ubs.TotalBadges,
    ubs.GoldBadges,
    ubs.SilverBadges,
    ubs.BronzeBadges    
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON rp.Tags LIKE '%' || ts.TagName || '%'
LEFT JOIN 
    UserBadgeSummary ubs ON rp.OwnerUserId = ubs.UserId
WHERE 
    rp.ScoreRank <= 5 -- Top 5 questions for each user
ORDER BY 
    rp.CreationDate DESC;
