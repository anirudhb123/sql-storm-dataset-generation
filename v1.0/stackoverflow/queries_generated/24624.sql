WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 2 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(P.Score) AS AvgScore,
        MAX(P.CreationDate) AS LastPostDate,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id
),

RecentEdits AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate AS EditDate,
        PH.UserDisplayName AS Editor,
        PH.Comment AS EditComment,
        ROW_NUMBER() OVER(PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS EditRank
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags Edits
),

PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS Upvotes,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS Downvotes,
        COUNT(PH.Id) FILTER (WHERE PH.PostHistoryTypeId IN (10, 11)) AS ClosureUpdates
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.AcceptedAnswers,
    COALESCE(PA.Upvotes, 0) AS TotalUpvotes,
    COALESCE(PA.Downvotes, 0) AS TotalDownvotes,
    COALESCE(PA.ClosureUpdates, 0) AS ClosureUpdates,
    R.Title AS RecentEditPostTitle,
    R.EditDate AS RecentEditDate,
    R.Editor AS RecentEditor,
    R.EditComment AS RecentEditComment
FROM 
    UserPostStats U
LEFT JOIN 
    PostActivity PA ON U.UserId = PA.PostId
LEFT JOIN 
    RecentEdits R ON R.EditRank = 1
ORDER BY 
    U.TotalPosts DESC, 
    U.AcceptedAnswers DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- Using NULL logic: filtering for users with no accepted answers but at least one post
UNION ALL

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    0 AS TotalPosts,
    0 AS Questions,
    0 AS Answers,
    0 AS AcceptedAnswers,
    0 AS TotalUpvotes,
    0 AS TotalDownvotes,
    0 AS ClosureUpdates,
    NULL AS RecentEditPostTitle,
    NULL AS RecentEditDate,
    NULL AS RecentEditor,
    NULL AS RecentEditComment
FROM 
    Users U
WHERE 
    U.Id NOT IN (SELECT OwnerUserId FROM Posts WHERE AcceptedAnswerId IS NOT NULL)
AND 
    U.Id IN (SELECT DISTINCT OwnerUserId FROM Posts);
