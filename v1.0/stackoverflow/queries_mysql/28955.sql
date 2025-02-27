
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TagSummary AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts 
    INNER JOIN 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
TopQuestions AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        ts.TagCount
    FROM
        RankedPosts rp
    JOIN
        TagSummary ts ON rp.Tags = ts.Tag
    WHERE
        rp.TagRank <= 10 
)
SELECT 
    tq.Title,
    tq.OwnerDisplayName,
    tq.CreationDate,
    tq.Score,
    tq.ViewCount,
    tq.AnswerCount,
    ts.Tag
FROM 
    TopQuestions tq
JOIN 
    TagSummary ts ON tq.TagCount = ts.TagCount
ORDER BY 
    tq.Score DESC, tq.ViewCount DESC;
