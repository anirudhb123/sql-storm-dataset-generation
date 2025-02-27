WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBountiesWon
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE(NULLIF(P.FavoriteCount, 0), 0) AS IsNotFavorited,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RankByCreationDate
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PS.*,
        UA.DisplayName,
        UA.Reputation
    FROM 
        PostStatistics PS
    JOIN 
        UserActivity UA ON PS.OwnerUserId = UA.UserId
    WHERE 
        PS.RankByCreationDate <= 5 -- Top 5 posts per user in the last year
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(PH.Id) AS CloseCount
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10 
    GROUP BY 
        P.Id
),
FinalReport AS (
    SELECT 
        TP.Title,
        TP.CreationDate,
        TP.Score,
        TP.ViewCount,
        TP.AnswerCount,
        TP.CommentCount,
        TP.DisplayName AS PostOwner,
        TP.Reputation AS OwnerReputation,
        CP.CloseCount
    FROM 
        TopPosts TP
    LEFT JOIN 
        ClosedPosts CP ON TP.PostId = CP.PostId
)
SELECT 
    *,
    CASE 
        WHEN CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN Reputation > 1000 THEN 'Respected Contributor'
        WHEN Reputation BETWEEN 500 AND 1000 THEN 'Growing Contributor'
        ELSE 'New Contributor'
    END AS ContributorStatus
FROM 
    FinalReport
ORDER BY 
    Score DESC, CreationDate DESC;
