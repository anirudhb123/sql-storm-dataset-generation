
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        DATE_FORMAT(p.CreationDate, '%Y-%m-01') AS PostMonth,
        RANK() OVER (PARTITION BY DATE_FORMAT(p.CreationDate, '%Y-%m-01') ORDER BY COUNT(DISTINCT v.Id) DESC) AS PostRank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= CURDATE() - INTERVAL 1 YEAR 
    GROUP BY
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        Body,
        Tags,
        Author,
        CommentCount,
        AnswerCount,
        PostMonth
    FROM
        RankedPosts
    WHERE
        PostRank = 1 
)
SELECT
    t.PostId,
    t.Title,
    t.Author,
    t.CommentCount,
    t.AnswerCount,
    t.PostMonth,
    GROUP_CONCAT(DISTINCT tr.TagName) AS Tags
FROM
    TopPosts t
LEFT JOIN
    (SELECT 
        DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName
     FROM 
        Posts
     INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    ) tr ON tr.TagName LIKE CONCAT('%', t.Tags, '%')
GROUP BY
    t.PostId, t.Title, t.Author, t.CommentCount, t.AnswerCount, t.PostMonth
ORDER BY
    t.PostMonth ASC;
