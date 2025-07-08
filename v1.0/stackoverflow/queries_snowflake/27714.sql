
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
TopTags AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount
    FROM (
        SELECT 
            TRIM(value) AS Tag
        FROM 
            Posts,
            LATERAL SPLIT_TO_TABLE(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><') AS value
        WHERE 
            PostTypeId = 1
    ) AS TagList
    GROUP BY 
        Tag
),
TagRankings AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TopTags
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.Author,
    rp.CreationDate,
    tr.Tag,
    tr.PostCount AS TotalPostsWithTag,
    tr.TagRank
FROM 
    RankedPosts rp
JOIN 
    TagRankings tr ON tr.Tag IN (SELECT TRIM(value) FROM LATERAL SPLIT_TO_TABLE(SUBSTRING(rp.Tags, 2, LENGTH(rp.Tags) - 2), '><') AS value)
WHERE 
    rp.RankByScore <= 5 
ORDER BY 
    tr.TagRank, 
    rp.RankByScore;
