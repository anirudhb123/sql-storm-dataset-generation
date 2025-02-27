WITH UserInsights AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(COALESCE(V.VoteCount, 0)) AS AvgVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        DATEDIFF(NOW(), P.CreationDate) AS DaysOld,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerName,
        COALESCE(C.CleanupCount, 0) AS CleanupCount
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CleanupCount 
        FROM 
            PostHistory 
        WHERE 
            PostHistoryTypeId IN (10, 11) 
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
    WHERE 
        P.CreationDate > DATE_SUB(NOW(), INTERVAL 30 DAY)
)
SELECT 
    U.DisplayName as UserDisplayName,
    U.Reputation,
    U.TotalPosts,
    R.PostId,
    R.Title,
    R.CreationDate,
    R.DaysOld,
    R.ViewCount,
    R.Score,
    R.OwnerName,
    R.CleanupCount,
    CASE 
        WHEN R.Score >= 10 THEN 'High Score' 
        WHEN R.Score BETWEEN 5 AND 9 THEN 'Moderate Score' 
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    UserInsights U
JOIN 
    RecentPosts R ON U.UserId = R.OwnerName
WHERE 
    U.TotalQuestions > 2 
    AND R.CleanupCount = 0
ORDER BY 
    U.Reputation DESC, 
    R.ViewCount DESC
LIMIT 100;
