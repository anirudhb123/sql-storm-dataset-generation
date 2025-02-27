WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Class,
        COUNT(*) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, B.Class
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS ViewRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= DATEADD(month, -6, GETDATE()) 
        AND P.Score > 0
),
RecentComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    WHERE 
        C.CreationDate >= DATEADD(day, -30, GETDATE())
    GROUP BY 
        C.PostId
),
Combined AS (
    SELECT 
        U.DisplayName AS UserName,
        P.Title AS PostTitle,
        COALESCE(RC.CommentCount, 0) AS RecentComments,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        PB.Class AS BadgeClass,
        PP.ViewRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        RecentComments RC ON P.Id = RC.PostId
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PopularPosts PP ON P.Id = PP.PostId
    LEFT JOIN 
        LATERAL (SELECT DISTINCT Class FROM UserBadges WHERE UserId = U.Id) PB ON true
    WHERE 
        U.Reputation > 100
)
SELECT 
    UserName,
    PostTitle,
    RecentComments,
    TotalBadges,
    COALESCE(BadgeClass, 0) AS BadgeClass,
    ViewRank
FROM 
    Combined
WHERE 
    ViewRank <= 10 OR TotalBadges > 5
ORDER BY 
    TotalBadges DESC,
    RecentComments DESC NULLS LAST;

This SQL query performs a multi-stage aggregation and filtering of data across several joined tables and Common Table Expressions (CTEs). It accomplishes the following tasks:

1. **UserBadges CTE**: Calculates the total count of badges for each user.
  
2. **PopularPosts CTE**: Retrieves popular posts from the last six months based on view count, ranking them.

3. **RecentComments CTE**: Counts recent comments made in the last thirty days for each post.

4. **Combined CTE**: Joins all previous CTEs and creates a unified dataset that reflects the number of badges, recent comments, and popularity rank of posts.

5. **Final Selection**: Filters for users with greater than 100 reputations, returning the top results based on current popularity and badge counts.

The query utilizes various SQL features, including outer joins, correlated subqueries, and window functions, along with NULL logic for explanation and aggregation across multiple conditions.
