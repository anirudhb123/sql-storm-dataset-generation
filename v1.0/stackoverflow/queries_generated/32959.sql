WITH RECURSIVE UserVoteCounts AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),

PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LatestActivity
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id AND A.PostTypeId = 2
    GROUP BY 
        P.Id, P.Title
),

PostHistoryStats AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PHT.Name AS HistoryType,
        COUNT(PH.Id) AS TotalChanges,
        MAX(PH.CreationDate) AS LastChangeDate
    FROM 
        PostHistory PH
    INNER JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId, PH.UserId, PHT.Name
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Upvotes,
    U.Downvotes,
    PS.PostId,
    PS.Title,
    PS.CommentCount,
    PS.AnswerCount,
    PS.AverageScore,
    PH.TotalChanges,
    PH.LastChangeDate,
    CASE 
        WHEN U.Upvotes > U.Downvotes THEN 'Positive'
        WHEN U.Upvotes < U.Downvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    UserVoteCounts U
JOIN 
    PostStats PS ON PS.CommentCount > 10  -- only interested in popular posts
LEFT JOIN 
    PostHistoryStats PH ON PH.PostId = PS.PostId
WHERE 
    PH.TotalChanges > 5  -- only consider posts with significant history changes
ORDER BY 
    U.Upvotes DESC, PS.AverageScore DESC;
