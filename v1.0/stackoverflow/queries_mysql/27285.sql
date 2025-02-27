
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.OwnerName,
        rp.AnswerCount,
        rp.CommentCount,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 10 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    TRIM(LEADING '<' FROM TRIM(TRAILING '>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, '>', n.n), '>', -1))) AS CleanedTag,
    fp.OwnerName,
    fp.AnswerCount,
    fp.CommentCount,
    TIMESTAMPDIFF(SECOND, fp.CreationDate, '2024-10-01 12:34:56') / 3600 AS AgeInHours
FROM 
    FilteredPosts fp
JOIN 
    (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
     UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
ON 
    CHAR_LENGTH(fp.Tags) - CHAR_LENGTH(REPLACE(fp.Tags, '>', '')) >= n.n - 1
ORDER BY 
    fp.CreationDate DESC
LIMIT 50;
