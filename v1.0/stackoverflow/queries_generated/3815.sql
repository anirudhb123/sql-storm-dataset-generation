WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(VoteCount) AS TotalVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),

ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalVotes,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalVotes DESC) AS Rank
    FROM UserActivity
    WHERE CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    AU.DisplayName,
    AU.PostCount,
    AU.TotalVotes,
    AU.BadgeCount,
    COALESCE(PH.RevisionGUID, 'N/A') AS LastPostRevision,
    COALESCE(CLOSE.CloseReason, 'Not Closed') AS CloseReason,
    (SELECT AVG(ViewCount) 
     FROM Posts 
     WHERE OwnerUserId = AU.UserId) AS AvgViewsPerPost
FROM ActiveUsers AU
LEFT JOIN Posts P ON AU.UserId = P.OwnerUserId
LEFT JOIN PostHistory PH ON P.Id = PH.PostId
LEFT JOIN (
    SELECT PostId, STRING_AGG(CloseReasonTypes.Name, ', ') AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes ON PH.Description = CloseReasonTypes.Id
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PostId
) CLOSE ON P.Id = CLOSE.PostId
WHERE AU.Rank <= 10
ORDER BY AU.Rank;
