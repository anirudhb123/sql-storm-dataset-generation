WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 1) AS TotalQuestions,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 2) AS TotalAnswers
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostHighlights AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.ViewCount DESC) AS RankViews
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        C.Name AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes C ON PH.Comment = CAST(C.Id AS VARCHAR)
    WHERE PH.PostHistoryTypeId = 10
),
FilteredPosts AS (
    SELECT 
        PH.PostId,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Comments C
    JOIN Posts P ON C.PostId = P.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY PH.PostId
),
FinalResult AS (
    SELECT 
        U.DisplayName AS UserName,
        U.Reputation,
        PS.Title,
        PS.ViewCount,
        PS.Score,
        RS.CloseReason,
        RS.CreationDate AS ClosedDate,
        FS.CommentCount
    FROM UserStats U
    JOIN PostHighlights PS ON U.TotalQuestions > 0
    LEFT JOIN ClosedPosts RS ON PS.PostId = RS.PostId
    LEFT JOIN FilteredPosts FS ON PS.PostId = FS.PostId
    WHERE U.Reputation > (SELECT AVG(Reputation) FROM Users) 
      AND U.TotalAnswers > 3
      AND (RS.CreationDate IS NULL OR RS.CreationDate < NOW() - INTERVAL '30 days')
)

SELECT 
    UserName,
    Reputation,
    Title,
    ViewCount,
    Score,
    COALESCE(CloseReason, 'Not Closed') AS CloseReason,
    ClosedDate,
    COALESCE(CommentCount, 0) AS CommentCount
FROM FinalResult
WHERE CloseReason IS NOT NULL OR CommentCount > 0
ORDER BY Reputation DESC, ViewCount DESC
LIMIT 100;
