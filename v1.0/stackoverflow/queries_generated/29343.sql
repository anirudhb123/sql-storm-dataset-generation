WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(vt.Value) AS TotalVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY
        p.Id, p.Title, pt.Name, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY TotalVotes DESC, CreationDate DESC) AS GlobalRank
    FROM
        RankedPosts
)
SELECT
    tp.PostId,
    tp.Title,
    tp.PostType,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.AnswerCount,
    tp.TotalVotes,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = tp.OwnerDisplayName) AS BadgeCount
FROM
    TopPosts tp
WHERE
    tp.GlobalRank <= 10
ORDER BY
    tp.TotalVotes DESC;
