
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @row_number := @row_number + 1 AS Rank
    FROM 
        Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId
    LEFT JOIN Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0) r
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopRankedPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, AnswerCount, UpVotes, DownVotes, Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 50
)
SELECT 
    tr.PostId,
    tr.Title,
    tr.CreationDate,
    tr.Score,
    tr.ViewCount,
    tr.AnswerCount,
    tr.UpVotes,
    tr.DownVotes,
    u.DisplayName AS AuthorName,
    u.Reputation,
    u.CreationDate AS UserCreationDate
FROM 
    TopRankedPosts tr
JOIN 
    Users u ON tr.PostId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = tr.PostId)
ORDER BY 
    tr.Rank;
