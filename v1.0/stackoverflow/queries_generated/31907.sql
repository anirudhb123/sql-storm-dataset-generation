WITH RecursivePostChain AS (
    SELECT p.Id, p.Title, p.CreationDate, p.AnswerCount, p.Score, p.AcceptedAnswerId,
           1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Start with Questions
    
    UNION ALL
    
    SELECT p.Id, p.Title, p.CreationDate, p.AnswerCount, p.Score, p.AcceptedAnswerId,
           rpc.Level + 1
    FROM Posts p
    JOIN RecursivePostChain rpc ON p.ParentId = rpc.Id
    WHERE p.PostTypeId = 2  -- Continue with Answers
),
PostStats AS (
    SELECT p.Id AS PostId, p.Title, 
           COALESCE(a.AnnualAnswerCount, 0) AS AnnualAnswerCount,
           COALESCE(v.VoteCount, 0) AS VoteCount,
           COALESCE(c.CommentCount, 0) AS CommentCount,
           COALESCE(ph.HistoryCount, 0) AS HistoryCount,
           DENSE_RANK() OVER (ORDER BY COALESCE(a.AnnualAnswerCount, 0) DESC) AS Rank
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS AnnualAnswerCount
        FROM Posts
        WHERE PostTypeId = 2 AND CreationDate >= DATEADD(year, -1, GETDATE())
        GROUP BY PostId
    ) a ON p.Id = a.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS HistoryCount
        FROM PostHistory
        GROUP BY PostId
    ) ph ON p.Id = ph.PostId
)
SELECT ps.PostId, ps.Title, ps.AnnualAnswerCount, ps.VoteCount, ps.CommentCount, 
       ps.HistoryCount, rpc.Level AS PostChainLevel,
       CASE 
            WHEN ps.Rank <= 10 THEN 'Top 10 Posts' 
            ELSE 'Other Posts' 
       END AS PostCategory
FROM PostStats ps
LEFT JOIN RecursivePostChain rpc ON ps.PostId = rpc.Id
WHERE ps.VoteCount > 5
ORDER BY ps.Rank, ps.VoteCount DESC
OPTION (MAXRECURSION 100);
