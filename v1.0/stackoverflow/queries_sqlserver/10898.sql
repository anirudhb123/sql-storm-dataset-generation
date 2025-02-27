
WITH UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCreated,
        COUNT(PH.Id) AS EditsMade
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN PostHistory PH ON U.Id = PH.UserId
    GROUP BY U.Id, U.DisplayName
)

SELECT 
    UserId,
    DisplayName,
    PostsCreated,
    EditsMade,
    (PostsCreated + EditsMade) AS TotalActivity
FROM UserActivity
ORDER BY TotalActivity DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
