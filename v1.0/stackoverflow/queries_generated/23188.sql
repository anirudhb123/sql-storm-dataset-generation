WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
),
PostVoteStatistics AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS Upvotes,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
FlaggedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RecentEdit,
        PH.UserId,
        PH.Comment AS ClosureReason
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10  -- Post Closed
    OR 
        PH.PostHistoryTypeId = 11  -- Post Reopened
),
TopUsersWithClosedPosts AS (
    SELECT 
        UR.DisplayName,
        COUNT(DISTINCT FP.PostId) AS ClosedPostCount
    FROM 
        UserReputation UR
    JOIN 
        Comments C ON UR.UserId = C.UserId
    JOIN 
        FlaggedPosts FP ON FP.UserId = C.UserId
    GROUP BY 
        UR.DisplayName
    HAVING 
        COUNT(DISTINCT FP.PostId) > 5
)
SELECT 
    PU.DisplayName,
    PU.Reputation,
    PU.ReputationRank,
    COALESCE(VS.Upvotes, 0) AS TotalUpvotes,
    COALESCE(VS.Downvotes, 0) AS TotalDownvotes,
    TUC.ClosedPostCount,
    CASE 
        WHEN U.Reputation IS NULL OR U.Reputation < 0 THEN 'Reputation Not Available'
        ELSE 'Reputation Available'
    END AS ReputationStatus,
    STUFF(
        (SELECT '; ' + PH.Reason
         FROM Comments AS PH
         WHERE PH.UserId = PU.Id
         FOR XML PATH('')), 1, 2, '') AS RecentComments
FROM 
    UserReputation PU
LEFT JOIN 
    PostVoteStatistics VS ON PU.UserId = VS.PostId
LEFT JOIN 
    TopUsersWithClosedPosts TUC ON PU.DisplayName = TUC.DisplayName
WHERE 
    PU.ReputationRank <= 10 AND
    PU.DisplayName IS NOT NULL
ORDER BY 
    PU.Reputation DESC;


### Explanation of the Query:
1. **CTEs (Common Table Expressions)**: 
   - **UserReputation**: Calculates each user's rank based on their reputation.
   - **PostVoteStatistics**: Counts the number of upvotes and downvotes each post has received.
   - **FlaggedPosts**: Gets a list of posts that have been closed or reopened, along with their closure reasons and the users responsible for the actions.
   - **TopUsersWithClosedPosts**: Selects users who have more than 5 closed posts and counts the closed post.

2. **Main Select**: 
   - Joins the various CTEs to get a comprehensive view of the top-ranked users, their voting record, and their interaction with closed posts.
   - Returns reputation status based on a condition on reputation values.
   - Uses a `STUFF()` subquery to concatenate recent comments for each user, demonstrating how to handle string aggregation in SQL.

3. **Handling NULL Values**: Utilizes `COALESCE()` to return 0 for users with no votes.

4. **Bizarre Semantics**: 
   - Incorporates a conditional clause that checks for NULL reputation and negative reputation as a quirky way of reporting.

This query serves as a complex exercise in handling various SQL constructs while maintaining readability and logical flow.
