WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS RankByViews
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year' 
        AND P.Score > 0
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    P.Title AS PopularPostTitle,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    COALESCE(CP.CloseReason, 'Not Closed') AS ClosureReason,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
    (SELECT STRING_AGG(T.TagName, ', ') 
     FROM Tags T 
     JOIN LATERAL unnest(string_to_array(P.Tags, '><')) AS Tag ON T.TagName = Tag) AS Tags
FROM 
    UserStats U
LEFT JOIN 
    PopularPosts P ON U.UserId = P.OwnerUserId AND P.RankByViews = 1
LEFT JOIN 
    ClosedPosts CP ON P.PostId = CP.PostId
WHERE 
    U.ReputationRank <= 10
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC NULLS LAST;
