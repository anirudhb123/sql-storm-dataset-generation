
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS VoteCount,
        COALESCE(SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END), 0) AS TotalViews,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.ClosedDate,
        @row_num := IF(@prev_owner_user_id = P.OwnerUserId, @row_num + 1, 1) AS RowNum,
        @prev_owner_user_id := P.OwnerUserId,
        RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P,
        (SELECT @row_num := 0, @prev_owner_user_id := NULL) AS vars
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
        AND P.Score IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        CTR.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CTR ON PH.Comment IS NOT NULL AND PH.PostHistoryTypeId = 10
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL 1 YEAR
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.VoteCount,
    UA.TotalViews,
    UA.CommentCount,
    UA.PostCount,
    PS.PostId,
    PS.Title,
    PS.CreationDate AS PostCreationDate,
    PS.ViewCount AS PostViewCount,
    PS.Score AS PostScore,
    PS.AnswerCount,
    PS.CommentCount AS PostCommentCount,
    (SELECT COUNT(*) FROM ClosedPosts CP WHERE CP.PostId = PS.PostId) AS CloseCount,
    CP.CloseReason
FROM 
    UserActivity UA
LEFT JOIN 
    PostStatistics PS ON UA.UserId = PS.RowNum
LEFT JOIN 
    ClosedPosts CP ON PS.PostId = CP.PostId
WHERE 
    UA.PostCount > 0
ORDER BY 
    UA.TotalViews DESC,
    UA.VoteCount DESC
LIMIT 50;
