-- Performance Benchmarking Query

WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id
)

SELECT
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalViews,
    u.TotalUpVotes,
    u.TotalDownVotes,
    (u.TotalUpVotes - u.TotalDownVotes) AS NetVotes,
    RANK() OVER (ORDER BY u.TotalViews DESC) AS ViewRank,
    RANK() OVER (ORDER BY u.TotalPosts DESC) AS PostRank
FROM
    UserPostStats u
ORDER BY
    u.TotalPosts DESC, u.TotalViews DESC;
