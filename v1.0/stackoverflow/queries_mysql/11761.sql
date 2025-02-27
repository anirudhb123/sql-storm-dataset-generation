
WITH PostStats AS (
    SELECT
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS PostMonth,
        COUNT(*) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(CommentCount) AS TotalComments
    FROM
        Posts
    WHERE
        CreationDate >= '2023-10-01 12:34:56'
    GROUP BY
        PostMonth
),
UserStats AS (
    SELECT
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS UserMonth,
        COUNT(*) AS TotalUsers,
        SUM(Reputation) AS TotalReputation,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM
        Users
    WHERE
        CreationDate >= '2023-10-01 12:34:56'
    GROUP BY
        UserMonth
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
LEFT JOIN
    UserStats us ON ps.PostMonth = us.UserMonth
UNION
SELECT
    us.UserMonth,
    NULL AS TotalPosts,
    NULL AS TotalViews,
    NULL AS TotalAnswers,
    NULL AS TotalComments,
    us.TotalUsers,
    us.TotalReputation,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM
    UserStats us
WHERE 
    us.UserMonth NOT IN (SELECT PostMonth FROM PostStats)
ORDER BY
    COALESCE(ps.PostMonth, us.UserMonth);
