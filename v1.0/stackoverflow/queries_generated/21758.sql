WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.DisplayName,
        U.Location,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation IS NOT NULL
    GROUP BY 
        U.Id
), 
HighReputationUsers AS (
    SELECT 
        UserId,
        Reputation,
        DisplayName,
        Location,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        AvgViewCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserMetrics
    WHERE 
        Reputation > 1000
), 
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.CreationDate > (NOW() - INTERVAL '1 year')
    GROUP BY 
        U.Id
), 
MergedActivity AS (
    SELECT 
        H.*,
        A.CommentCount,
        A.UpvoteCount,
        A.DownvoteCount,
        COALESCE(NULLIF(A.CommentCount, 0), 1) AS SafeCommentCount
    FROM 
        HighReputationUsers H
    LEFT JOIN 
        UserActivity A ON H.UserId = A.UserId
)
SELECT *
FROM MergedActivity
WHERE 
    (TotalPosts > 10 OR TotalQuestions > 5)
    AND (CommentCount IS NULL OR UpvoteCount > DownvoteCount)
ORDER BY 
    TotalScore DESC, AvgViewCount DESC;

-- Analyzing post history for closed posts with corresponding reasons
WITH ClosedPostHistory AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate AS ClosedDate,
        C.Name AS CloseReasonName,
        PH.UserDisplayName,
        PH.Comment
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)
    ORDER BY 
        PH.CreationDate DESC    
)
SELECT 
    *
FROM 
    ClosedPostHistory
WHERE 
    ClosedDate >= (NOW() - INTERVAL '1 month')
ORDER BY 
    ClosedDate DESC;

