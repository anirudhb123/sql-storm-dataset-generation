-- Performance Benchmarking SQL Query

WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.Reputation AS OwnerReputation,
        COUNT(a.Id) AS AnswerCount
    FROM
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Posts a ON p.Id = a.ParentId
    WHERE
        p.PostTypeId = 1  -- Filtering for questions
    GROUP BY
        p.Id, u.Reputation
),
TopPosts AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS PostRank
    FROM
        RankedPosts
)
SELECT
    Id,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerUserId,
    OwnerReputation,
    AnswerCount
FROM
    TopPosts
WHERE
    PostRank <= 10; -- Top 10 high scored and viewed questions
