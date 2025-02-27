WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RowRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND 
        (P.Score > 10 OR P.ViewCount > 1000)
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PHT.Name AS HistoryType,
        PH.UserId,
        U.DisplayName AS EditorName,
        PH.Comment
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        PH.CreationDate BETWEEN NOW() - INTERVAL '1 year' AND NOW()
        AND PH.PostHistoryTypeId IN (10, 11, 12, 13)
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.CommentCount,
    UA.BadgeCount,
    UA.TotalViews,
    UA.TotalUpVotes,
    UA.TotalDownVotes,
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.CreationDate AS PostCreationDate,
    PH.PostHistoryTypeId,
    PH.HistoryType,
    PH.CreationDate AS HistoryCreationDate,
    PH.EditorName,
    PH.Comment
FROM 
    UserActivity UA
LEFT JOIN 
    PostStatistics PS ON UA.UserId = PS.OwnerUserId AND PS.RowRank = 1
LEFT JOIN 
    PostHistoryDetails PH ON PS.PostId = PH.PostId
WHERE 
    UA.TotalDownVotes < UA.TotalUpVotes
ORDER BY 
    UA.Reputation DESC,
    UA.TotalViews DESC,
    UA.LastPostDate DESC
LIMIT 100;
