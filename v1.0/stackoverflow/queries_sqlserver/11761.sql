
WITH PostStats AS (
    SELECT
        DATEADD(month, DATEDIFF(month, 0, CreationDate), 0) AS PostMonth,
        COUNT(*) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(CommentCount) AS TotalComments
    FROM
        Posts
    WHERE
        CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
    GROUP BY
        DATEADD(month, DATEDIFF(month, 0, CreationDate), 0)
),
UserStats AS (
    SELECT
        DATEADD(month, DATEDIFF(month, 0, CreationDate), 0) AS UserMonth,
        COUNT(*) AS TotalUsers,
        SUM(Reputation) AS TotalReputation,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM
        Users
    WHERE
        CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
    GROUP BY
        DATEADD(month, DATEDIFF(month, 0, CreationDate), 0)
)
SELECT
    ps.PostMonth,
    ps.TotalPosts,
    ps.TotalViews,
    ps.TotalAnswers,
    ps.TotalComments,
    us.TotalUsers,
    us.TotalReputation,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM
    PostStats ps
FULL OUTER JOIN
    UserStats us ON ps.PostMonth = us.UserMonth
ORDER BY
    COALESCE(ps.PostMonth, us.UserMonth);
