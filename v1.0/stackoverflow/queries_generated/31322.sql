WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS DownVotes,
        SUM(COALESCE(C.Comment, 0)) AS CommentCount
    FROM 
        Users U 
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId 
    LEFT JOIN 
        Comments C ON P.Id = C.PostId 
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRank
    FROM 
        Posts P 
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
PostStatistics AS (
    SELECT 
        RP.RecentRank,
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.ViewCount,
        RP.Score,
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.CommentCount
    FROM 
        RecentPosts RP
    JOIN 
        UserActivity UA ON RP.PostId = UA.UserId
    WHERE 
        RP.RecentRank = 1
)
SELECT 
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.DisplayName,
    PS.Reputation,
    PS.CommentCount,
    CASE 
        WHEN PS.Score >= 10 THEN 'Hot'
        WHEN PS.Score BETWEEN 5 AND 9 THEN 'Warm'
        ELSE 'Cold'
    END AS PostTemperature,
    COALESCE(
        (SELECT 
            COUNT(*) 
        FROM 
            Comments C
        WHERE 
            C.PostId = PS.PostId AND C.CreationDate >= NOW() - INTERVAL '1 month'), 
        0
    ) AS RecentCommentCount,
    (SELECT 
        STRING_AGG(TAG.TagName, ', ') 
    FROM 
        Posts AS P
    JOIN 
        Tags TAG ON TAG.ExcerptPostId = P.Id 
    WHERE 
        P.Id = PS.PostId) AS TagsList
FROM 
    PostStatistics PS
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 100;

In this query, we are performing multiple operations:

1. **CTEs**: The `UserActivity` CTE aggregates user-related stats while excluding those with zero reputation. The `RecentPosts` CTE fetches recent posts from the last year and assigns rankings based on creation date. The `PostStatistics` CTE combines the above to focus on recent post data linked to user information.

2. **Outer Joins**: We utilize LEFT JOINs to ensure that we include all users, even if they have not authored any posts or votes.

3. **Correlated Subqueries**: We use correlated subqueries to calculate the count of recent comments and derive a list of tags for each post.

4. **Window Functions**: ROW_NUMBER function is used to rank recent posts based on creation time.

5. **CASE Statement**: Used to classify posts into temperature categories based on their score.

6. **String Aggregation**: STRING_AGG function collects tags associated with a post into a single comma-separated string.

This query aggregates data effectively to give insights into user activity and the popularity of posts, suitable for performance benchmarking against various SQL constructs.
