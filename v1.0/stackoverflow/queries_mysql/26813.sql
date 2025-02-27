
WITH TagStatistics AS (
    SELECT
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        GROUP_CONCAT(U.DisplayName SEPARATOR ', ') AS ActiveUsers
    FROM
        Tags T
    JOIN
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    JOIN
        Users U ON P.OwnerUserId = U.Id
    GROUP BY
        T.TagName
    HAVING
        COUNT(P.Id) > 5
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        Questions,
        Answers,
        ActiveUsers,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        TagStatistics
)
SELECT
    T.TagName,
    T.PostCount,
    T.Questions,
    T.Answers,
    T.ActiveUsers,
    (SELECT COUNT(*) FROM Posts P WHERE P.Tags LIKE CONCAT('%', T.TagName, '%')) AS TotalViews,
    (SELECT MAX(Date) FROM Badges B WHERE B.UserId IN (SELECT U.Id FROM Users U JOIN Posts P ON P.OwnerUserId = U.Id WHERE P.Tags LIKE CONCAT('%', T.TagName, '%'))) AS LastBadgeDate
FROM
    TopTags T
WHERE
    T.Rank <= 10
ORDER BY
    T.PostCount DESC;
