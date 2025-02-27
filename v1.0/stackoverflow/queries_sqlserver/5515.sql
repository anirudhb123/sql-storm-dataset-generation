
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
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
        AND p.Score > 0
),
PopularTags AS (
    SELECT 
        LTRIM(RTRIM(value)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
    WHERE 
        PostTypeId = 1
    GROUP BY 
        LTRIM(RTRIM(value))
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        STRING_AGG(pt.TagName, ', ') AS Tags
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS pt ON LTRIM(RTRIM(pt.value)) IN (SELECT TagName FROM PopularTags)
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
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
