WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  -- Only count BountyStart and BountyClose votes
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(COALESCE(C.Comment, 0)) AS CommentCount,
        SUM(CASE WHEN P.Score IS NULL OR P.Score < 0 THEN 0 ELSE P.Score END) AS TotalScore,
        MAX(CreationDate) AS LatestCommentDate
    FROM 
        Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.OwnerUserId
),
AccumulatedVotes AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
PostsWithHistory AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastHistoryDate,
        STRING_AGG(DISTINCT PHT.Name, ', ' ORDER BY PHT.Name) AS HistoryTypes
    FROM 
        PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
FinalStats AS (
    SELECT 
        U.UserId,
        U.Reputation,
        U.PostCount,
        U.TotalBounty,
        P.PostId,
        P.CommentCount,
        P.TotalScore,
        COALESCE(A.UpVotes, 0) AS UpVotes,
        COALESCE(A.DownVotes, 0) AS DownVotes,
        COALESCE(H.LastHistoryDate, DATE '1970-01-01') AS LastHistoryDate,
        COALESCE(H.HistoryTypes, 'None') AS HistoryTypes
    FROM 
        UserReputation U
    JOIN PostStats P ON U.UserId = P.OwnerUserId
    LEFT JOIN AccumulatedVotes A ON P.PostId = A.PostId
    LEFT JOIN PostsWithHistory H ON P.PostId = H.PostId
)
SELECT 
    FS.UserId,
    FS.Reputation,
    FS.PostCount,
    FS.TotalBounty,
    FS.PostId,
    FS.CommentCount,
    FS.TotalScore,
    FS.UpVotes,
    FS.DownVotes,
    FS.LastHistoryDate,
    FS.HistoryTypes
FROM 
    FinalStats FS
WHERE 
    FS.Reputation > 1000
    AND (FS.TotalScore > 50 OR FS.CommentCount > 10)
ORDER BY 
    FS.Reputation DESC, FS.TotalScore DESC;
