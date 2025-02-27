WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS ViewRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id
),
ClosedAndEditedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS EditCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    R.Title,
    R.ViewCount,
    R.UpVotes,
    R.DownVotes,
    COALESCE(CAE.CloseCount, 0) AS CloseCount,
    COALESCE(CAE.EditCount, 0) AS EditCount
FROM 
    RankedPosts R
JOIN 
    Users U ON R.PostId = U.Id
LEFT JOIN 
    ClosedAndEditedPosts CAE ON R.PostId = CAE.PostId
WHERE 
    R.ViewRank <= 5
    AND R.UpVotes > R.DownVotes
    AND R.ViewCount IS NOT NULL
ORDER BY 
    R.ViewRank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

WITH UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
PopularTags AS (
    SELECT 
        T.TagName, 
        SUM(V.VoteTypeId = 2) AS TotalUpVotes
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        T.TagName
    HAVING 
        SUM(V.VoteTypeId = 2) > 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.Location,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    PT.TagName,
    PT.TotalUpVotes
FROM 
    Users U 
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
JOIN 
    PopularTags PT ON PT.TotalUpVotes > 10
WHERE 
    U.Reputation > 1000 AND U.Location IS NOT NULL
ORDER BY 
    U.Reputation DESC, PT.TotalUpVotes DESC;

This SQL query consists of two parts:

1. **RankedPosts CTE**: This part calculates the rank of posts based on view counts per user, along with counts of upvotes and downvotes. It ensures we retrieve posts created in the last year and focuses specifically on those that have more upvotes than downvotes. The results are limited to the top 5 ranked posts viewed by the users.

2. **ClosedAndEditedPosts CTE**: This subquery computes the number of times a post was closed and edited, which helps in analyzing the engagement metrics of the posts.

3. The main selection then joins these with the **Users** table to fetch user details and combines with badge information and tag popularity in two additional CTEs, filtering again based on reputation and location criteria.

This structure allows for performance benchmarking through complex joins, aggregates, CTE usage, and intricate WHERE clauses, showcasing the power of SQL in analyzing public forum data while incorporating NULL handling, window functions, and complex predicates.
