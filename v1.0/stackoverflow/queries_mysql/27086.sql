
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.Id ORDER BY MAX(v.CreationDate) DESC) AS RankByLastActive
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByLastActive = 1
),
TagFrequency AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        FilteredPosts
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagFrequency
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.OwnerDisplayName,
    t.TagName,
    t.TagCount
FROM 
    FilteredPosts fp
JOIN 
    TopTags t ON fp.Tags LIKE CONCAT('%', t.TagName, '%')
WHERE 
    t.TagRank <= 5 
ORDER BY 
    fp.PostId, t.TagCount DESC;
