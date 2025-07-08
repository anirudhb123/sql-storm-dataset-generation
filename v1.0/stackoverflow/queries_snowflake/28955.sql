
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
        TRIM(TRANSLATE(value, '><', '')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts,
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTRING(Tags, 2, LENGTH(Tags)-2), '><')) AS value)
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TRIM(TRANSLATE(value, '><', ''))
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
