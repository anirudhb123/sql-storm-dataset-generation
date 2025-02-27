-- Performance benchmarking query to analyze the number of posts, views, and user engagement over time
WITH PostStats AS (
    SELECT
        DATE_TRUNC('month', CreationDate) AS PostMonth,
        COUNT(*) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(CommentCount) AS TotalComments
    FROM
        Posts
    WHERE
        CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY
        PostMonth
),
UserStats AS (
    SELECT
        DATE_TRUNC('month', CreationDate) AS UserMonth,
        COUNT(*) AS TotalUsers,
        SUM(Reputation) AS TotalReputation,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM
        Users
    WHERE
        CreationDate >= NOW() - INTERVAL '1 year'
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
FULL OUTER JOIN
    UserStats us ON ps.PostMonth = us.UserMonth
ORDER BY
    COALESCE(ps.PostMonth, us.UserMonth);
