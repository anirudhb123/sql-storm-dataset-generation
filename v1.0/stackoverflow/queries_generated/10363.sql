-- Performance benchmarking query to retrieve users with the highest reputation and their respective post counts
WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
)

SELECT 
    UPC.UserId,
    UPC.DisplayName,
    UPC.Reputation,
    UPC.PostCount
FROM UserPostCounts UPC
ORDER BY UPC.Reputation DESC, UPC.PostCount DESC
LIMIT 10;

-- Performance benchmarking query to analyze the average score of posts by type
SELECT 
    PT.Name AS PostType,
    AVG(P.Score) AS AverageScore
FROM Posts P
JOIN PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY PT.Name
ORDER BY AverageScore DESC;

-- Performance benchmarking query to find the most common close reasons for posts
SELECT 
    CRT.Name AS CloseReason,
    COUNT(PH.Id) AS CloseReasonCount
FROM PostHistory PH
JOIN CloseReasonTypes CRT ON PH.Comment::int = CRT.Id -- Assuming comment stores the close reason ID
WHERE PH.PostHistoryTypeId IN (10, 11) -- Close and Reopen actions
GROUP BY CRT.Name
ORDER BY CloseReasonCount DESC;

-- Performance benchmarking query to evaluate the trend of post creation over time (monthly)
SELECT 
    DATE_TRUNC('month', P.CreationDate) AS CreationMonth,
    COUNT(P.Id) AS PostCount
FROM Posts P
GROUP BY CreationMonth
ORDER BY CreationMonth;
