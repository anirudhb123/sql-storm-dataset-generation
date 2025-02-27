WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        COALESCE(Ph.CreationDate, P.CreationDate) AS LastActivityDate,
        CASE 
            WHEN Ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN Ph.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Active' 
        END AS PostStatus
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory Ph ON P.Id = Ph.PostId AND Ph.CreationDate = (
            SELECT MAX(Ph2.CreationDate) 
            FROM PostHistory Ph2 
            WHERE Ph2.PostId = P.Id
        )
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.CommentCount,
    U.BadgeCount,
    MAX(P.Score) AS MaxPostScore,
    SUM(CASE WHEN P.PostStatus = 'Closed' THEN 1 ELSE 0 END) AS ClosedPostCount,
    COUNT(DISTINCT T.TagName) AS UniqueTagCount,
    STRING_AGG(DISTINCT CASE WHEN P.PostStatus = 'Closed' THEN P.Title ELSE NULL END, ', ') AS ClosedPostTitles
FROM 
    UserStatistics U
JOIN 
    PostActivity P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    UNNEST(string_to_array(P.Tags, ',')) AS T(TagName) ON TRUE
WHERE 
    U.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND U.BadgeCount > 0
GROUP BY 
    U.DisplayName, U.Reputation, U.PostCount, U.CommentCount, U.BadgeCount
HAVING 
    COUNT(DISTINCT P.PostId) >= 10 
    AND ABS(MAX(P.Score)) >= 5
ORDER BY 
    U.Reputation DESC
LIMIT 100;

-- Additional Aggregate Metric for Performance Benchmarking
WITH AggMetrics AS (
    SELECT 
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        AVG(U.Reputation) AS AvgReputation,
        P.PostTypeId,
        SUM(CASE WHEN P.Score IS NULL THEN 1 ELSE 0 END) AS NULLScoreCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.PostTypeId
)
SELECT 
    A.PostTypeId,
    A.TotalPosts,
    A.TotalViews,
    A.AvgReputation,
    A.NULLScoreCount,
    CASE 
        WHEN A.TotalViews > 1000 THEN 'High'
        WHEN A.TotalViews <= 1000 AND A.TotalViews > 100 THEN 'Medium'
        ELSE 'Low' 
    END AS ViewCategory
FROM 
    AggMetrics A
WHERE 
    A.TotalPosts > 50
ORDER BY 
    A.TotalViews DESC;
