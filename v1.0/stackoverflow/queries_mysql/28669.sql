
WITH PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
    (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        pwt.PostId,
        pwt.Title,
        pwt.Body,
        pwt.CreationDate,
        pwt.ViewCount,
        pwt.AnswerCount,
        pwt.CommentCount,
        COUNT(*) OVER(PARTITION BY pwt.Tag) AS TagCount 
    FROM 
        PostWithTags pwt
    WHERE 
        pwt.ViewCount > 100 
),
RankedPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Body,
        fp.CreationDate,
        fp.ViewCount,
        fp.AnswerCount,
        fp.CommentCount,
        fp.TagCount,
        @rank := @rank + 1 AS Rank
    FROM 
        FilteredPosts fp
    JOIN (SELECT @rank := 0) r
    ORDER BY 
        fp.TagCount DESC, fp.ViewCount DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.TagCount,
    rp.Rank,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.PostId = u.Id
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Rank;
