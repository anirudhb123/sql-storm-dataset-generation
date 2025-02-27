WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(VoteType.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        (SELECT 
             PostId,
             SUM(CASE WHEN VoteTypeId IN (2, 1) THEN 1 ELSE 0 END) AS Score
         FROM 
             Votes
         GROUP BY 
             PostId) AS VoteType ON P.Id = VoteType.PostId
    GROUP BY 
        U.Id
), PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        P.Title,
        P.CreationDate,
        PH.CreationDate AS HistoryDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)
), ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.HistoryDate,
        U.DisplayName AS ClosingUser,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM 
        Posts P
    JOIN 
        PostHistoryDetails PH ON P.Id = PH.PostId
    JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        PH.HistoryRank = 1
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.TotalPosts,
    US.Questions,
    US.Answers,
    US.TotalScore,
    COALESCE(CP.PostId, 0) AS ClosedPostId,
    COALESCE(CP.Title, 'No Closed Posts') AS ClosedPostTitle,
    COALESCE(CP.HistoryDate, NULL) AS ClosedDate,
    COALESCE(CP.ClosingUser, 'N/A') AS ClosedBy,
    COALESCE(CP.CommentCount, 0) AS CommentsOnClosedPost
FROM 
    UserStatistics US
LEFT JOIN 
    ClosedPosts CP ON US.UserId = CP.ClosingUser
ORDER BY 
    US.TotalPosts DESC, US.TotalScore DESC;
