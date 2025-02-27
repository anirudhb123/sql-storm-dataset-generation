WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        AVG(U.Views) AS AverageViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
),
ActiveUsers AS (
    SELECT 
        UserId, 
        Reputation,
        PostCount,
        TotalBounty,
        AverageViews,
        Upvotes,
        Downvotes,
        ActivityRank
    FROM 
        UserActivity
    WHERE 
        ActivityRank <= 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(STRING_AGG(DISTINCT T.TagName, ', '), 'No Tags') AS Tags,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS Status
    FROM 
        Posts P
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(P.Tags, '><')) AS TagName ON TRUE
    LEFT JOIN 
        Tags T ON T.TagName = TagName
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, P.ClosedDate
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UA.PostCount,
    UA.TotalBounty,
    UA.AverageViews,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.AnswerCount,
    PD.Tags,
    PD.Status
FROM 
    ActiveUsers UA
JOIN 
    Users U ON UA.UserId = U.Id
LEFT JOIN 
    PostDetails PD ON PD.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id)
ORDER BY 
    UA.Reputation DESC, 
    PD.Score DESC;

### Explanation:
1. **CTEs**: 
   - `UserActivity`: Gathers user statistics including post counts, total bounty collected, and upvotes/downvotes. It also ranks users based on their activity.
   - `ActiveUsers`: Filters down to the top 10 active users based on their activity rank.
   - `PostDetails`: Extracts details of posts along with tag names, using aggregation functions and a string manipulation to handle tags.

2. **LEFT JOINs & CORRELATED SUBQUERIES**: Used to join tables and collect votes and tags while handling potential NULLs gracefully.

3. **String Aggregation**: Collects tags into a single string, demonstrating string manipulation capabilities.

4. **Case Statements**: Provides a human-readable status of posts (Closed/Open).

5. **Window Functions**: Utilized for ranking user activity within the first CTE.

This query can help in performance benchmarking by assessing the system's ability to handle multiple joins, subqueries, and complex aggregations while retrieving useful analytical insights about the most active users and their post contributions.
