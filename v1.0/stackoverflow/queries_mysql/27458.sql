
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
             SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1) AS TagName, 
             Id 
         FROM 
             Posts
         JOIN 
             (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers 
         ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1) AS t ON p.Id = t.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.Tags,
        b.Name AS BadgeName,
        b.Class AS BadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (
            SELECT 
                Id 
            FROM 
                Users 
            WHERE 
                DisplayName = rp.OwnerDisplayName
            LIMIT 1
        )
),
AggregatedData AS (
    SELECT 
        pwb.PostId,
        pwb.Title,
        pwb.Body,
        pwb.CreationDate,
        pwb.ViewCount,
        pwb.Score,
        pwb.OwnerDisplayName,
        pwb.Tags,
        AVG(CASE WHEN pwb.BadgeClass = 1 THEN 1.0 ELSE 0 END) AS GoldBadges,
        AVG(CASE WHEN pwb.BadgeClass = 2 THEN 1.0 ELSE 0 END) AS SilverBadges,
        AVG(CASE WHEN pwb.BadgeClass = 3 THEN 1.0 ELSE 0 END) AS BronzeBadges
    FROM 
        PostWithBadges pwb
    GROUP BY 
        pwb.PostId, pwb.Title, pwb.Body, pwb.CreationDate, pwb.ViewCount, pwb.Score, pwb.OwnerDisplayName, pwb.Tags
)
SELECT 
    ad.PostId,
    ad.Title,
    ad.Body,
    ad.CreationDate,
    ad.ViewCount,
    ad.Score,
    ad.OwnerDisplayName,
    ad.Tags,
    ad.GoldBadges,
    ad.SilverBadges,
    ad.BronzeBadges,
    (SELECT COUNT(*) FROM AggregatedData WHERE Score > ad.Score) + 1 AS RankByScore,
    (SELECT COUNT(*) FROM AggregatedData WHERE ViewCount > ad.ViewCount) + 1 AS RankByViews
FROM 
    AggregatedData ad
WHERE 
    ad.ViewCount > 50  
ORDER BY 
    ad.Score DESC, ad.ViewCount DESC
LIMIT 10;
