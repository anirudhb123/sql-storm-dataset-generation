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
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate > NOW() - INTERVAL '1 year'
),
TopTaggedPosts AS (
    SELECT 
        rp.*, 
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        RankedPosts rp
    JOIN 
        STRING_TO_ARRAY(rp.Tags, '<>') AS tag ON tag IS NOT NULL
    JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag)
    WHERE 
        rp.TagRank <= 5
    GROUP BY 
        rp.PostId
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
