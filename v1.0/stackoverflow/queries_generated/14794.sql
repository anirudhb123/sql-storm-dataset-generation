-- Benchmarking performance for posts with more than 10 answers and their associated users and votes
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AnswerCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.AnswerCount > 10
    GROUP BY p.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.AnswerCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.VoteCount
FROM RankedPosts rp
ORDER BY rp.VoteCount DESC, rp.AnswerCount DESC;
