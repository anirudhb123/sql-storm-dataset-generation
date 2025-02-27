WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        B.Date,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM Users U
    JOIN Badges B ON U.Id = B.UserId
), TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersCount,
        COALESCE(SUM(P.Score), 0) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
), RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) as RN
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
    ORDER BY P.CreationDate DESC
), TopVotes AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    GROUP BY V.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    MAX(B.BadgeName) FILTER (WHERE B.BadgeRank = 1) AS TopBadge,
    COALESCE(Q.QuestionsCount, 0) AS TotalQuestions,
    COALESCE(A.AnswersCount, 0) AS TotalAnswers,
    COALESCE(T.TotalScore, 0) AS TotalScore,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    V.UpVotes,
    V.DownVotes
FROM TopUsers U
LEFT JOIN UserBadges B ON U.UserId = B.UserId
LEFT JOIN TopUsers Q ON U.UserId = Q.UserId
LEFT JOIN TopUsers A ON U.UserId = A.UserId
LEFT JOIN RecentPosts RP ON RP.RN <= 5
LEFT JOIN TopVotes V ON RP.Id = V.PostId
WHERE U.Reputation >= 100
GROUP BY U.UserId, U.DisplayName, U.Reputation, RP.Title, RP.CreationDate, RP.Score, RP.ViewCount, RP.OwnerDisplayName, V.UpVotes, V.DownVotes
ORDER BY U.Reputation DESC, RP.CreationDate DESC;
