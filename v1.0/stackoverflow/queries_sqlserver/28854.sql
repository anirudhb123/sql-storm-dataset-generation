
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
        LTRIM(RTRIM(SUBSTRING(tag, 2, LEN(tag) - 2))) AS TagName
    FROM 
        RankedPosts,
        STRING_SPLIT(REPLACE(Tags, '><', '> <'), ' ') AS tag
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
)
SELECT TOP 20
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
    MostCommonTags mct ON CHARINDEX(mct.TagName, rp.Tags) > 0
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.Score, rp.ViewCount, rp.CommentCount
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
