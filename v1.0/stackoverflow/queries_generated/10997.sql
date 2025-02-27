-- Performance Benchmarking Query
WITH PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        AVG(CASE WHEN h.PostHistoryTypeId = 10 THEN 1 ELSE NULL END) AS CloseRate
    FROM
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory h ON p.Id = h.PostId
    WHERE
        p.CreationDate >= '2023-01-01'
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount
)

SELECT
    COUNT(PostId) AS TotalPosts,
    AVG(ViewCount) AS AverageViewCount,
    AVG(Score) AS AverageScore,
    AVG(AnswerCount) AS AverageAnswerCount,
    AVG(CommentCount) AS AverageCommentCount,
    SUM(VoteCount) AS TotalVotes,
    AVG(CloseRate) AS AverageCloseRate
FROM
    PostStatistics;

