
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
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        INNER JOIN 
            Posts p ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
        WHERE 
            p.PostTypeId = 1
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
    TagRankings tr ON FIND_IN_SET(tr.Tag, TRIM(BOTH ' ' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', numbers.n), '><', -1))) 
WHERE 
    rp.RankByScore <= 5 
ORDER BY 
    tr.TagRank, 
    rp.RankByScore;
