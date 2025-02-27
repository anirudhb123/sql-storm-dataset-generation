
WITH PostActivity AS (
    SELECT
        YEAR(CreationDate) AS Year,
        MONTH(CreationDate) AS Month,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM
        Posts
    WHERE
        CreationDate >= CURRENT_DATE - INTERVAL 1 YEAR
    GROUP BY
        YEAR(CreationDate),
        MONTH(CreationDate)
),
UserActivity AS (
    SELECT
        YEAR(CreationDate) AS Year,
        MONTH(CreationDate) AS Month,
        COUNT(DISTINCT Id) AS TotalUsers
    FROM
        Users
    WHERE
        CreationDate >= CURRENT_DATE - INTERVAL 1 YEAR
    GROUP BY
        YEAR(CreationDate),
        MONTH(CreationDate)
)
SELECT
    p.Year,
    p.Month,
    p.TotalPosts,
    p.TotalQuestions,
    p.TotalAnswers,
    p.TotalViews,
    p.TotalScore,
    u.TotalUsers
FROM
    PostActivity p
JOIN
    UserActivity u ON p.Year = u.Year AND p.Month = u.Month
ORDER BY
    p.Year DESC, p.Month DESC;
