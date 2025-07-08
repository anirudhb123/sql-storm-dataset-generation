
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
    TRIM(LEADING '<' FROM TRIM(TRAILING '>' FROM VALUE)) AS CleanedTag,
    fp.OwnerName,
    fp.AnswerCount,
    fp.CommentCount,
    DATEDIFF('second', fp.CreationDate, '2024-10-01 12:34:56') / 3600 AS AgeInHours
FROM 
    FilteredPosts fp,
    TABLE(FLATTEN(INPUT => SPLIT(fp.Tags, '>'))) AS TagsTable
ORDER BY 
    fp.CreationDate DESC
LIMIT 50;
