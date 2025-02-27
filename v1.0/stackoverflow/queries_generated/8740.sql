WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(COALESCE(VoteTypeValue, 0)) AS TotalVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId 
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN (
        SELECT PostId, SUM(CASE 
            WHEN VoteTypeId = 2 THEN 1
            WHEN VoteTypeId = 3 THEN -1 
            ELSE 0 END) AS VoteTypeValue
        FROM Votes 
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    GROUP BY U.Id
), MostActiveUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.PostCount,
        UA.CommentCount,
        UA.TotalVotes,
        ROW_NUMBER() OVER (ORDER BY UA.PostCount DESC) AS Rank
    FROM UserActivity UA
)
SELECT 
    M.UserId,
    M.DisplayName,
    M.Reputation,
    M.PostCount,
    M.CommentCount,
    M.TotalVotes,
    PH.PostHistoryTypeId,
    COUNT(PH.Id) AS HistoryCount
FROM MostActiveUsers M
JOIN PostHistory PH ON M.UserId = PH.UserId
WHERE M.Rank <= 10
GROUP BY 
    M.UserId, M.DisplayName, M.Reputation, M.PostCount, M.CommentCount, M.TotalVotes, PH.PostHistoryTypeId
ORDER BY M.Rank, HistoryCount DESC;
