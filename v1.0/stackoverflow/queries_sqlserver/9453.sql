
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        LEN(REPLACE(p.Tags, '>', '')) - LEN(REPLACE(p.Tags, '>', '')) + 1 AS TagCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Id ORDER BY p.Score DESC) AS PostRank,
        pt.Name AS PostType
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
    GROUP BY
        p.Id, p.Title, p.Score, p.ViewCount, pt.Id, pt.Name
),
TopPosts AS (
    SELECT 
        rp.*,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS OverallRank
    FROM 
        RankedPosts rp
    WHERE
        rp.PostRank = 1
)
SELECT
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.TagCount,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.PostType,
    tp.OverallRank
FROM
    TopPosts tp
WHERE
    tp.OverallRank <= 10
ORDER BY
    tp.OverallRank;
