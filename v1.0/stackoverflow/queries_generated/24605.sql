WITH UserReputationData AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN H.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseCount,
        SUM(V.VoteTypeId = 2) AS UpvoteCount,
        SUM(V.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Users AS U
    LEFT JOIN 
        Badges AS B ON U.Id = B.UserId
    LEFT JOIN 
        PostHistory AS H ON U.Id = H.UserId
    LEFT JOIN 
        Votes AS V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation
), 
UserActivitySummary AS (
    SELECT
        UserId,
        Reputation,
        BadgeCount,
        CloseCount,
        UpvoteCount,
        DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY Reputation ORDER BY BadgeCount DESC) AS UserRank
    FROM 
        UserReputationData
    WHERE 
        Reputation IS NOT NULL
), 
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Posts AS P
    LEFT JOIN 
        Comments AS C ON P.Id = C.PostId
    LEFT JOIN 
        Votes AS V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.AcceptedAnswerId
),
CombinedData AS (
    SELECT 
        U.UserId,
        U.Reputation,
        P.PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.CommentCount,
        P.TotalUpvotes,
        P.TotalDownvotes,
        CASE 
            WHEN U.UserRank <= 10 THEN 'Top Contributor'
            WHEN U.UserRank <= 50 THEN 'Promising Contributor'
            ELSE 'New Contributor' 
        END AS ContributorStatus
    FROM 
        UserActivitySummary AS U
    INNER JOIN 
        PostSummary AS P ON U.UserId = P.AcceptedAnswerId
    WHERE 
        U.BadgeCount > 0
)
SELECT 
    DISTINCT CD.*, 
    PHT.Name AS PostHistoryType
FROM 
    CombinedData AS CD
LEFT JOIN 
    PostHistory AS PH ON CD.PostId = PH.PostId
LEFT JOIN 
    PostHistoryTypes AS PHT ON PH.PostHistoryTypeId = PHT.Id
WHERE 
    (PHT.Id IS NULL OR PHT.Class = 1) -- Getting only gold badges or null history types
    AND CD.Reputation >= 1000
ORDER BY 
    CD.Reputation DESC, 
    CD.CommentCount DESC, 
    CD.Title DESC;
