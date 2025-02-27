-- Performance benchmarking query
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(DISTINCT P.Id) AS PostCount,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    AVG(P.Score) AS AverageScore,
    AVG(P.ViewCount) AS AverageViewCount,
    AVG(COALESCE(C.CommentCount, 0)) AS AverageCommentCount,
    AVG(COALESCE(V.BountyAmount, 0)) AS AverageBountyAmount,
    COUNT(DISTINCT B.Id) AS BadgeCount
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN Comments C ON P.Id = C.PostId
LEFT JOIN Votes V ON P.Id = V.PostId
LEFT JOIN Badges B ON U.Id = B.UserId
WHERE U.Reputation > 1000
GROUP BY U.Id, U.DisplayName
ORDER BY PostCount DESC
LIMIT 10;
