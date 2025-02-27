
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankWithinUser
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
        AND p.Score > 0
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        GROUP_CONCAT(pt.TagName) AS Tags
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        PopularTags pt ON FIND_IN_SET(pt.TagName, SUBSTRING(SUBSTRING_INDEX(p.Tags, '<', -1), 1, LENGTH(p.Tags))) > 0
    WHERE 
        rp.RankWithinUser = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.Score, rp.ViewCount
)
SELECT 
    tpd.PostId,
    tpd.Title,
    tpd.OwnerDisplayName,
    tpd.Score,
    tpd.ViewCount,
    tpd.Tags AS RelatedTags
FROM 
    TopPostDetails tpd
ORDER BY 
    tpd.Score DESC, tpd.ViewCount DESC
LIMIT 20;
