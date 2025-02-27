
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        GROUP_CONCAT(DISTINCT T.TagName) AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', numbers.n), '<', -1) AS TagName
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers) AS T ON TRUE
    WHERE 
        P.CreationDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.AcceptedAnswerId
)
SELECT 
    UEng.UserId,
    UEng.DisplayName,
    UEng.TotalPosts,
    UEng.TotalComments,
    UEng.TotalBounty,
    UEng.TotalUpvotes,
    UEng.TotalDownvotes,
    PA.PostId,
    PA.Title,
    PA.Score,
    PA.ViewCount,
    PA.AcceptedAnswerId,
    PA.Tags
FROM 
    UserEngagement UEng
JOIN 
    PostAnalytics PA ON UEng.UserId = PA.AcceptedAnswerId
ORDER BY 
    UEng.TotalUpvotes DESC, UEng.TotalPosts DESC, PA.Score DESC
LIMIT 100;
