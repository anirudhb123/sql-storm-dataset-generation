WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        U.DisplayName AS Author,
        p.Score,
        p.ViewCount,
        p.Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankValue
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- posts created in the last year
),
PostTags AS (
    SELECT 
        PostId,
        TRIM(value) AS Tag
    FROM 
        RankedPosts,
        LATERAL STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><') AS value
),
PopularTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PostTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Author,
    RP.CreationDate,
    RP.Score,
    PT.Tag AS PopularTag
FROM 
    RankedPosts RP
JOIN 
    PostTags PTag ON RP.PostId = PTag.PostId
JOIN 
    PopularTags PT ON PTag.Tag = PT.Tag
WHERE 
    RP.RankValue <= 5 -- top 5 posts per type
ORDER BY 
    RP.PostTypeId, RP.Score DESC, RP.ViewCount DESC;
