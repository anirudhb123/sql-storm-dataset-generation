
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @row_number := @row_number + 1 AS Rank
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Posts a ON p.Id = a.ParentId 
        LEFT JOIN Votes v ON p.Id = v.PostId 
        CROSS JOIN (SELECT @row_number := 0) AS r
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerReputation,
    AnswerCount,
    UpVotes,
    DownVotes
FROM 
    RankedPosts
WHERE 
    Rank <= 100 
ORDER BY 
    CreationDate DESC;
