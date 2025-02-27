
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR)
),
TopTaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title, 
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        GROUP_CONCAT(DISTINCT TRIM(BOTH '<>' FROM tag) ORDER BY tag SEPARATOR ', ') AS TagList
    FROM 
        RankedPosts rp
    JOIN 
        (SELECT TRIM(BOTH '<>' FROM tag) AS tag FROM JSON_TABLE(
                CONCAT('["', REPLACE(rp.Tags, '<>', '","'), '"]'),
                '$[*]' COLUMNS (tag VARCHAR(255) PATH '$')
        )) AS tag ON tag IS NOT NULL
    WHERE 
        rp.TagRank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.ViewCount, rp.Score
),
PopularPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        ViewCount,
        Score,
        TagList,
        RANK() OVER (ORDER BY ViewCount DESC) AS PopularityRank
    FROM 
        TopTaggedPosts
)

SELECT 
    pp.PostId,
    pp.Title,
    pp.OwnerDisplayName,
    pp.ViewCount,
    pp.Score,
    pp.TagList
FROM 
    PopularPosts pp
WHERE 
    pp.PopularityRank <= 10
ORDER BY 
    pp.ViewCount DESC;
