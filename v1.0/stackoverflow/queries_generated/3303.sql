WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM Posts P
    WHERE P.PostTypeId = 1 AND P.Score > 10
),
RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(V.VoteTypeId) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    WHERE V.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY V.PostId
),
CloseReason AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CAST(CRT.Name AS VARCHAR), ', ') AS Reasons
    FROM PostHistory PH
    JOIN CloseReasonTypes CRT ON PH.Comment::INT = CRT.Id
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    COALESCE(RV.TotalVotes, 0) AS TotalVotes,
    COALESCE(RV.UpVotes, 0) AS UpVotes,
    COALESCE(RV.DownVotes, 0) AS DownVotes,
    CR.Reasons
FROM RankedPosts RP
JOIN Users U ON RP.OwnerUserId = U.Id
LEFT JOIN RecentVotes RV ON RP.PostId = RV.PostId
LEFT JOIN CloseReason CR ON RP.PostId = CR.PostId
WHERE RP.UserPostRank = 1
ORDER BY RP.Score DESC, RP.CreationDate ASC
LIMIT 10;
