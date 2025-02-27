
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
        p.PostTypeId = 1  
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, u.Reputation
),
TopPosts AS (
    SELECT
        *,
        @row_number := IF(@prev_score = Score, @row_number + 1, 1) AS PostRank,
        @prev_score := Score
    FROM
        RankedPosts, (SELECT @row_number := 0, @prev_score := NULL) AS vars
    ORDER BY
        Score DESC, ViewCount DESC
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
    PostRank <= 10;
