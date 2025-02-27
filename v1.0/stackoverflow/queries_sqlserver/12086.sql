
WITH UserPostStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(DATEDIFF(SECOND, P.CreationDate, P.LastActivityDate)) AS AvgActiveDuration
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName
)
SELECT
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.TotalViews,
    U.TotalScore,
    U.AvgActiveDuration
FROM
    UserPostStats U
ORDER BY
    U.TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
