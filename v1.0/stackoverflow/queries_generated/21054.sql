WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= (NOW() - INTERVAL '1 year') 
        AND P.Score IS NOT NULL
        AND (P.ViewCount > 0 OR P.AcceptedAnswerId IS NOT NULL)
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, U.DisplayName
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        RP.TotalComments
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank <= 5
),
PostVoteCounts AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes V
    INNER JOIN 
        VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY 
        V.PostId
)
SELECT 
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.OwnerDisplayName,
    TP.TotalComments,
    COALESCE(PVC.UpVoteCount, 0) AS UpVotes,
    COALESCE(PVC.DownVoteCount, 0) AS DownVotes,
    CASE 
        WHEN TP.Score > 0 THEN 'Positive'
        WHEN TP.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreCategory,
    CASE 
        WHEN TP.TotalComments > 10 THEN 'Highly Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    TopPosts TP
LEFT JOIN 
    PostVoteCounts PVC ON TP.PostId = PVC.PostId
ORDER BY 
    TP.Score DESC,
    TP.TotalComments DESC
LIMIT 10;

-- Additional Queries based on unusual edge cases
SELECT 
    (SELECT COUNT(*) 
     FROM Users U 
     WHERE U.Reputation IS NOT NULL) AS NonNullReputationUsers,
    (SELECT COUNT(*) 
     FROM Users U 
     WHERE U.Reputation IS NULL) AS NullReputationUsers,
    (SELECT AVG(VB.Count) 
     FROM (SELECT Count AS Count 
           FROM Tags 
           WHERE IsModeratorOnly = 1) AS VB) AS AvgModeratorTags
HAVING 
    NonNullReputationUsers > NullReputationUsers
    AND AvgModeratorTags WHAT != 0;

-- Detect potential post notices that are correlated with user reputation
SELECT 
    PH.PostId,
    PH.UserDisplayName,
    PH.Comment,
    (SELECT AVG(U.Reputation) 
     FROM Users U 
     WHERE U.Id = PH.UserId) AS AvgUserReputation
FROM 
    PostHistory PH
WHERE 
    PH.PostHistoryTypeId IN (33, 34) 
    AND PH.UserId IS NOT NULL
    AND EXISTS (SELECT 1 
                FROM Users U 
                WHERE U.Id = PH.UserId AND U.Reputation < 100)
ORDER BY 
    AvgUserReputation DESC
LIMIT 5;
