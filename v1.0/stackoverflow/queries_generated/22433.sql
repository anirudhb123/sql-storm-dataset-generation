WITH RankedPosts AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.CreationDate,
           P.Score,
           P.ViewCount,
           RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    AND P.Score IS NOT NULL
),
AggregateStats AS (
    SELECT PT.Name AS PostType,
           COUNT(RP.PostId) AS TotalPosts,
           AVG(RP.Score) AS AvgScore,
           AVG(RP.ViewCount) AS AvgViews
    FROM RankedPosts RP
    JOIN PostTypes PT ON RP.PostRank = 1
    GROUP BY PT.Name
),
TopUsers AS (
    SELECT U.DisplayName,
           SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
           DENSE_RANK() OVER (ORDER BY SUM(COALESCE(V.BountyAmount, 0)) DESC) AS BountyRank
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE V.VoteTypeId = 8 -- BountyStart
    GROUP BY U.DisplayName
    HAVING SUM(COALESCE(V.BountyAmount, 0)) > 0
),
ClosedPosts AS (
    SELECT PH.PostId,
           MAX(PH.CreationDate) AS LastClosedDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY PH.PostId
),
PostClosureStats AS (
    SELECT RP.PostId,
           RP.Title,
           C.LastClosedDate,
           COALESCE(DATEDIFF('minute', C.LastClosedDate, NOW()), 0) AS MinutesSinceClosed
    FROM RankedPosts RP
    LEFT JOIN ClosedPosts C ON RP.PostId = C.PostId
    WHERE RP.PostRank = 1
)
SELECT AST.PostType,
       AST.TotalPosts,
       AST.AvgScore,
       AST.AvgViews,
       PU.DisplayName AS TopUser,
       PU.TotalBounties,
       PCS.Title,
       PCS.MinutesSinceClosed,
       CASE 
           WHEN PCS.MinutesSinceClosed > 60 THEN 'More than an hour since closure' 
           ELSE 'Recently closed' 
       END AS ClosureStatus
FROM AggregateStats AST
JOIN PostClosureStats PCS ON AST.PostType = (SELECT PT.Name FROM PostTypes PT WHERE PT.Id = (SELECT PostTypeId FROM Posts WHERE Id = PCS.PostId LIMIT 1))
JOIN TopUsers PU ON PU.BountyRank = 1
ORDER BY AST.AvgScore DESC, PU.TotalBounties DESC;
