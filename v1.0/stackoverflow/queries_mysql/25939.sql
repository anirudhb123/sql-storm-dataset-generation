
WITH PostTagCounts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(v.Id) AS VoteCount
    FROM
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        p.Id, p.Title
),
RankedTags AS (
    SELECT
        TagName,
        COUNT(PostId) AS TagPostCount,
        SUM(VoteCount) AS TotalVotes,
        RANK() OVER (ORDER BY SUM(VoteCount) DESC) AS TagRank
    FROM
        PostTagCounts
    GROUP BY
        TagName
),
TopTags AS (
    SELECT
        TagName
    FROM
        RankedTags
    WHERE
        TagRank <= 5
),
TopPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN c.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount
    FROM
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    INNER JOIN PostTagCounts pt ON p.Id = pt.PostId
    INNER JOIN TopTags tt ON pt.TagName = tt.TagName
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount
    ORDER BY
        CommentCount DESC, ViewCount DESC
    LIMIT 10
)
SELECT
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    GROUP_CONCAT(pt.TagName) AS AssociatedTags
FROM
    TopPosts tp
JOIN
    PostTagCounts pt ON tp.Id = pt.PostId
GROUP BY
    tp.Title, tp.CreationDate, tp.ViewCount, tp.CommentCount
ORDER BY
    tp.CommentCount DESC, tp.ViewCount DESC;
