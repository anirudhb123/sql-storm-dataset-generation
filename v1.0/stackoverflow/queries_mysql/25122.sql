
WITH PostTagCounts AS (
    SELECT
        p.Id AS PostId,
        COUNT(DISTINCT t.Id) AS TagCount
    FROM
        Posts p
    JOIN
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag_name
         FROM Posts p
         JOIN (
             SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION
             SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
         ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        ) AS tag_names ON true
    JOIN
        Tags t ON t.TagName = tag_names.tag_name
    GROUP BY
        p.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(p.Title, 'No Title') AS Title,
        pt.Name AS PostType,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.ViewCount,
        pc.TagCount
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        PostTagCounts pc ON p.Id = pc.PostId
    WHERE
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TopPostStats AS (
    SELECT
        PostId,
        Title,
        PostType,
        Owner,
        CreationDate,
        ViewCount,
        @rank := @rank + 1 AS Rank
    FROM
        PostDetails, (SELECT @rank := 0) r
    ORDER BY
        ViewCount DESC
)

SELECT
    tp.PostId,
    tp.Title,
    tp.PostType,
    tp.Owner,
    tp.CreationDate,
    tp.ViewCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) AS DownVoteCount
FROM
    TopPostStats tp
WHERE
    tp.Rank <= 10
ORDER BY
    tp.Rank;
