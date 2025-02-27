
WITH MostActiveUsers AS (
    SELECT U.Id, U.DisplayName, COUNT(P.Id) AS PostCount, SUM(ISNULL(P.ViewCount, 0)) AS TotalViews
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 1000 
    GROUP BY U.Id, U.DisplayName
),
TopPostTags AS (
    SELECT value AS Tag, COUNT(P.Id) AS PostCount
    FROM Posts P
    CROSS APPLY STRING_SPLIT(P.Tags, ',') 
    WHERE P.PostTypeId = 1 
    GROUP BY value
    ORDER BY PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
TagPostDetails AS (
    SELECT T.Tag, P.Title, P.Score, C.CreationDate
    FROM TopPostTags T
    JOIN Posts P ON P.Tags LIKE '%' + T.Tag + '%'
    JOIN Comments C ON P.Id = C.PostId
)
SELECT A.DisplayName, T.Tag, COUNT(DISTINCT P.Id) AS RelatedPosts, AVG(P.Score) AS AvgPostScore, MAX(C.CreationDate) AS LastCommentDate
FROM MostActiveUsers A
JOIN TagPostDetails T ON A.DisplayName = T.Tag
JOIN Posts P ON T.Title = P.Title
JOIN Comments C ON P.Id = C.PostId
GROUP BY A.DisplayName, T.Tag
ORDER BY RelatedPosts DESC, AvgPostScore DESC;
