
WITH MostActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(IFNULL(P.ViewCount, 0)) AS TotalViews,
        SUM(IF(P.Score > 0, 1, 0)) AS PositiveScores,
        SUM(IF(P.Score < 0, 1, 0)) AS NegativeScores,
        @row_number := @row_number + 1 AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    CROSS JOIN (SELECT @row_number := 0) AS r
    WHERE 
        U.Reputation IS NOT NULL
    GROUP BY 
        U.Id, U.DisplayName
),
TopPostTags AS (
    SELECT 
        T.TagName,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(DISTINCT P.Id) > 10
),
LatestPostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.LastActivityDate,
        IFNULL(COUNT(C.Id), 0) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        CASE
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed'
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Answered'
            ELSE 'Open'
        END AS PostStatus,
        @activity_rank := IF(P.OwnerUserId = @last_user_id, @activity_rank + 1, 1) AS ActivityRank,
        @last_user_id := P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON B.UserId = P.OwnerUserId
    CROSS JOIN (SELECT @activity_rank := 0, @last_user_id := NULL) AS r
    GROUP BY 
        P.Id, P.Title, P.LastActivityDate, P.ClosedDate, P.AcceptedAnswerId, P.OwnerUserId
)
SELECT 
    A.UserId,
    A.DisplayName,
    A.PostCount,
    A.TotalViews,
    A.PositiveScores,
    A.NegativeScores,
    T.TagName,
    T.TotalViews AS TagTotalViews,
    T.PostCount AS TagPostCount,
    L.PostId,
    L.Title,
    L.LastActivityDate,
    L.CommentCount,
    L.BadgeCount,
    L.PostStatus
FROM 
    MostActiveUsers A
CROSS JOIN 
    TopPostTags T
JOIN 
    LatestPostActivity L ON A.UserId = L.OwnerUserId 
WHERE 
    A.Rank <= 10 AND L.ActivityRank = 1
    AND (L.CommentCount > 5 OR L.BadgeCount > 2)
    AND (L.PostStatus = 'Open' OR L.PostStatus = 'Answered')
ORDER BY 
    A.TotalViews DESC, 
    T.TotalViews DESC, 
    L.LastActivityDate DESC;
