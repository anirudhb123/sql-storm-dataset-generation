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
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS TagName
    FROM 
        RankedPosts
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
    STRING_AGG(mct.TagName, ', ') AS PopularTags
FROM 
    RankedPosts rp
JOIN 
    MostCommonTags mct ON mct.TagName = ANY(string_to_array(rp.Tags, '><'))
GROUP BY 
    rp.PostId
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 20;
