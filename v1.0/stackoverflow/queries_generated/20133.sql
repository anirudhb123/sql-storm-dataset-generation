WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT PH.Id) AS HistoryCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
UserRank AS (
    SELECT 
        UserId,
        DisplayName,
        Upvotes,
        Downvotes,
        PostCount,
        CommentCount,
        BadgeCount,
        HistoryCount,
        DENSE_RANK() OVER (ORDER BY Upvotes DESC) AS UpvoteRank,
        DENSE_RANK() OVER (ORDER BY Downvotes DESC) AS DownvoteRank
    FROM 
        UserActivity
),
TopUsers AS (
    SELECT 
        *,
        CASE 
            WHEN UpvoteRank <= 10 THEN 'Top Upvoted'
            WHEN DownvoteRank <= 10 THEN 'Top Downvoted'
            ELSE 'Regular' 
        END AS UserClass
    FROM 
        UserRank
)
SELECT 
    DisplayName,
    Upvotes,
    Downvotes,
    PostCount,
    CommentCount,
    BadgeCount,
    HistoryCount,
    UserClass,
    CASE 
        WHEN PostCount > 5 THEN 'Active User'
        ELSE 'New User'
    END AS UserCategory,
    COALESCE(
        (SELECT STRING_AGG(Name, ', ') 
         FROM PostHistoryTypes 
         WHERE Id IN (SELECT DISTINCT PH.PostHistoryTypeId 
                      FROM PostHistory PH 
                      WHERE PH.UserId = U.UserId)),
        'No Actions') AS UserActions
FROM 
    TopUsers U
WHERE 
    UserClass IN ('Top Upvoted', 'Top Downvoted')
    OR UserCategory = 'Active User'
ORDER BY 
    Upvotes DESC, Downvotes ASC;

This SQL query delivers a comprehensive overview of user engagement through various metrics across posts, comments, votes, badges, and history actions while considering both upvotes and downvotes rankings. It incorporates CTEs, outer joins, window functions, and intricate case logic to create meaningful user classifications and provide a detailed summary of user actions. The use of the `STRING_AGG` function gathers post history types related to each user, adding another layer of contextual understanding, and handles NULL cases gracefully with COALESCE.
