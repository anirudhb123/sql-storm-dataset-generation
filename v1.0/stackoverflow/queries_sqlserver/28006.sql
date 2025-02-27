
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN p.PostTypeId = 1 THEN (SELECT COUNT(*) FROM Posts WHERE ParentId = p.Id)
            ELSE 0 
        END AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > '2023-01-01'
        AND p.Body IS NOT NULL
),
TagStatistics AS (
    SELECT
        value AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS TagList
    WHERE 
        PostTypeId = 1
    GROUP BY
        value
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 1
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    tt.Tag AS TopTag,
    tt.PostCount AS TagPostCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON tt.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags) - 2), '><'))
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
