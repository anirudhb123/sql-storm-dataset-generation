
WITH MostActiveUsers AS (
    SELECT U.Id, U.DisplayName, COUNT(P.Id) AS PostCount, SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 1000 
    GROUP BY U.Id, U.DisplayName
),
TopPostTags AS (
    SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', n.n), ',', -1) AS Tag, COUNT(P.Id) AS PostCount
    FROM Posts P
    JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= n.n - 1
    WHERE P.PostTypeId = 1 
    GROUP BY Tag
    ORDER BY PostCount DESC
    LIMIT 10
),
TagPostDetails AS (
    SELECT T.Tag, P.Title, P.Score, C.CreationDate
    FROM TopPostTags T
    JOIN Posts P ON FIND_IN_SET(T.Tag, P.Tags)
    JOIN Comments C ON P.Id = C.PostId
)
SELECT A.DisplayName, T.Tag, COUNT(DISTINCT P.Id) AS RelatedPosts, AVG(P.Score) AS AvgPostScore, MAX(C.CreationDate) AS LastCommentDate
FROM MostActiveUsers A
JOIN TagPostDetails T ON A.DisplayName = T.Tag
JOIN Posts P ON T.Title = P.Title
JOIN Comments C ON P.Id = C.PostId
GROUP BY A.DisplayName, T.Tag
ORDER BY RelatedPosts DESC, AvgPostScore DESC;
