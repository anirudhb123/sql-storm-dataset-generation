-- Performance benchmarking query to analyze the number of posts, average score, and vote counts grouped by post types

WITH PostSummary AS (
    SELECT
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        SUM(vt.VoteTypeId = 2) AS TotalUpVotes,
        SUM(vt.VoteTypeId = 3) AS TotalDownVotes
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN
        Votes vt ON p.Id = vt.PostId
    GROUP BY
        pt.Name
)

SELECT
    PostType,
    TotalPosts,
    AverageScore,
    TotalUpVotes,
    TotalDownVotes
FROM
    PostSummary
ORDER BY
    TotalPosts DESC;
