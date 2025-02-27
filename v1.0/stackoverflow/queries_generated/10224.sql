-- Performance Benchmarking Query
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerReputation
FROM
    RankedPosts rp
WHERE
    rp.Rank <= 10
ORDER BY
    rp.Score DESC;
