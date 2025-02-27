
WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName
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
    (SELECT COUNT(*) FROM UserPostStats WHERE TotalViews > u.TotalViews) + 1 AS ViewRank,
    (SELECT COUNT(*) FROM UserPostStats WHERE TotalPosts > u.TotalPosts) + 1 AS PostRank
FROM
    UserPostStats u
ORDER BY
    u.TotalPosts DESC, u.TotalViews DESC;
