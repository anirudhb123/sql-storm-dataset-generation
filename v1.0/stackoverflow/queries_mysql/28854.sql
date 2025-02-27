
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.Body, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopTags AS (
    SELECT 
        TRIM(SUBSTRING(tag, 2, LENGTH(tag) - 2)) AS TagName
    FROM 
        RankedPosts,
        JSON_UNQUOTE(JSON_EXTRACT(SUBSTRING_INDEX(CONCAT('><', Tags, '><'), '><', -1), '$.tag')) AS tag
),
MostCommonTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        TopTags
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    GROUP_CONCAT(mct.TagName SEPARATOR ', ') AS PopularTags
FROM 
    RankedPosts rp
JOIN 
    MostCommonTags mct ON FIND_IN_SET(mct.TagName, rp.Tags) > 0
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.Score, rp.ViewCount, rp.CommentCount
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 20;
