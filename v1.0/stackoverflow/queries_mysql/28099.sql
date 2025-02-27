
WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS UpVoteCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, p.Tags, u.DisplayName
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS TagName, 
        COUNT(*) AS TagCount
    FROM TaggedPosts
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    GROUP BY TagName
),
TopTags AS (
    SELECT TagName 
    FROM PopularTags 
    WHERE TagCount > 10 
    ORDER BY TagCount DESC
    LIMIT 5
),
Benchmarking AS (
    SELECT
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.UpVoteCount,
        pt.TagName
    FROM TaggedPosts tp
    JOIN TopTags pt ON tp.Tags LIKE CONCAT('%', pt.TagName, '%')
    ORDER BY tp.UpVoteCount DESC, tp.CommentCount DESC
    LIMIT 10
)
SELECT 
    b.PostId,
    b.Title,
    b.Body,
    b.OwnerDisplayName,
    b.CommentCount,
    b.UpVoteCount,
    b.TagName,
    CASE 
        WHEN b.CommentCount > 5 THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM Benchmarking b
ORDER BY b.UpVoteCount DESC;
