WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        Rank() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation >= 500 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationTier
    FROM Users
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.AcceptedAnswerId,
        P.OwnerUserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN C.Id END) AS CommentCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id
),
PostDetails AS (
    SELECT 
        PS.PostId,
        PS.PostTypeId,
        PS.UpVotes,
        PS.DownVotes,
        PS.CommentCount,
        PT.Name AS PostTypeName,
        U.DisplayName AS PostOwner,
        R.Rank AS ReputationRank
    FROM PostSummary PS
    JOIN PostTypes PT ON PS.PostTypeId = PT.Id
    LEFT JOIN UserReputation U ON PS.OwnerUserId = U.UserId
    LEFT JOIN (SELECT UserId, RANK() OVER (ORDER BY Reputation DESC) AS Rank FROM Users) R ON U.UserId = R.UserId
),
ClosedPostCounts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        COUNT(DISTINCT CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.UserId END) AS UniqueClosers
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11)  -- closed or reopened
    GROUP BY PH.PostId
),
FinalPostReport AS (
    SELECT 
        PD.PostId,
        PD.PostTypeName,
        PD.UpVotes,
        PD.DownVotes,
        PD.CommentCount,
        COALESCE(CPC.CloseCount, 0) AS CloseCount,
        COALESCE(CPC.UniqueClosers, 0) AS UniqueClosers,
        PD.PostOwner,
        CASE 
            WHEN PD.UpVotes > PD.DownVotes THEN 'Positive'
            WHEN PD.UpVotes < PD.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM PostDetails PD
    LEFT JOIN ClosedPostCounts CPC ON PD.PostId = CPC.PostId
)
SELECT 
    FPR.PostId,
    FPR.PostTypeName,
    FPR.UpVotes,
    FPR.DownVotes,
    FPR.CommentCount,
    FPR.CloseCount,
    FPR.UniqueClosers,
    FPR.PostOwner,
    FPR.VoteSentiment,
    CASE 
        WHEN FPR.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN FPR.UniqueClosers > 5 THEN 'Moderately Closed'
        WHEN FPR.UniqueClosers > 0 THEN 'Rarely Closed'
        ELSE 'Never Closed'
    END AS ClosureIntensity
FROM FinalPostReport FPR
WHERE FPR.UpVotes - FPR.DownVotes > 0 OR FPR.CloseCount > 0
ORDER BY FPR.UpVotes DESC, FPR.DownVotes ASC;
