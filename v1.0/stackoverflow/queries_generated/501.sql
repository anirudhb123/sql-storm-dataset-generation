WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        Upvotes,
        Downvotes,
        CommentCount,
        RANK() OVER (ORDER BY Reputation DESC, PostCount DESC) AS UserRank
    FROM 
        UserActivity
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(A.UserId, -1) AS AcceptedAnswerUserId,
        COALESCE(A.Title, 'No Accepted Answer') AS AcceptedAnswerTitle,
        T.TagName
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.AcceptedAnswerId = A.Id
    JOIN 
        (SELECT Id, UNNEST(STRING_TO_ARRAY(Tags, '><')) AS TagName FROM Posts) T ON T.Id = P.Id
    WHERE 
        P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
),
RecentPostStats AS (
    SELECT 
        P.PostId,
        COUNT(C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpvoteCount,
        SUM(V.VoteTypeId = 3) AS DownvoteCount
    FROM 
        ActivePosts P
    LEFT JOIN 
        Comments C ON C.PostId = P.PostId
    LEFT JOIN 
        Votes V ON V.PostId = P.PostId
    GROUP BY 
        P.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(AP.PostId, -1) AS PostId,
    COALESCE(AP.Title, 'No Posts') AS PostTitle,
    COALESCE(RP.CommentCount, 0) AS TotalComments,
    COALESCE(RP.UpvoteCount, 0) AS TotalUpvotes,
    COALESCE(RP.DownvoteCount, 0) AS TotalDownvotes
FROM 
    TopUsers U
LEFT JOIN 
    ActivePosts AP ON U.UserId = AP.AcceptedAnswerUserId
LEFT JOIN 
    RecentPostStats RP ON AP.PostId = RP.PostId
WHERE 
    U.UserRank <= 10
ORDER BY 
    U.Reputation DESC;
