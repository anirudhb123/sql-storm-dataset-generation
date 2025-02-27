
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Tags, u.DisplayName
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS TagName
    FROM 
        Posts 
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
         UNION ALL SELECT 9 UNION ALL SELECT 10) n ON CHAR_LENGTH(Tags) 
         -CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1
),
TagPopularity AS (
    SELECT 
        TagName,
        COUNT(*) AS UsageCount
    FROM 
        PopularTags 
    GROUP BY 
        TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 10
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.Score,
    RP.OwnerName,
    RP.Rank,
    TP.TagName,
    TP.UsageCount
FROM 
    RankedPosts RP
JOIN 
    TagPopularity TP ON FIND_IN_SET(TP.TagName, REPLACE(RP.Tags, '><', ',')) 
WHERE 
    RP.Rank <= 3 
ORDER BY 
    RP.OwnerName, RP.Score DESC, RP.ViewCount DESC;
