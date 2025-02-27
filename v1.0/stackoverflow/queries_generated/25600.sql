WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.Tags, u.DisplayName
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.Tags,
        rp.Author,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
    ORDER BY 
        rp.Score DESC
    LIMIT 10
),
TagAnalysis AS (
    SELECT 
        TRIM(REPLACE(REPLACE(SUBSTRING_INDEX(SUBSTRING_INDEX(tp.Tags, '<>', 1), '<>', -1), '<', ''), '>', '')) AS Tag,
        COUNT(tp.PostId) AS TagCount
    FROM 
        TopQuestions tp
    GROUP BY 
        Tag
),
MostCommonTags AS (
    SELECT 
        Tag,
        TagCount
    FROM 
        TagAnalysis
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.CreationDate,
    tq.Score,
    tq.Author,
    tq.CommentCount,
    STRING_AGG(mct.Tag, ', ') AS CommonTags
FROM 
    TopQuestions tq
LEFT JOIN 
    MostCommonTags mct ON tq.Tags LIKE CONCAT('%', mct.Tag, '%')
GROUP BY 
    tq.PostId, tq.Title, tq.CreationDate, tq.Score, tq.Author, tq.CommentCount
ORDER BY 
    tq.Score DESC;
