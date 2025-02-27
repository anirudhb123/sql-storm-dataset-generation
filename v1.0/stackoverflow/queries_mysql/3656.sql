
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(IFNULL(P.ViewCount, 0)) AS TotalViews,
        @row_num1 := @row_num1 + 1 AS EngagementRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    CROSS JOIN (SELECT @row_num1 := 0) AS r
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), MostActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostDate,
        P.Score,
        P.ViewCount,
        IFNULL(COUNT(C.Id), 0) AS CommentCount,
        IFNULL(SUM(V.BountyAmount), 0) AS TotalBounties,
        @row_num2 := @row_num2 + 1 AS ActivityRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    CROSS JOIN (SELECT @row_num2 := 0) AS r
    WHERE 
        P.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
)
SELECT 
    U.DisplayName AS User,
    U.PostCount,
    U.UpVotes,
    U.DownVotes,
    U.CommentCount,
    U.TotalViews,
    P.Title AS ActivePost,
    P.PostDate,
    P.Score AS PostScore,
    P.CommentCount AS ActivePostCommentCount,
    P.TotalBounties
FROM 
    UserEngagement U
LEFT JOIN 
    MostActivePosts P ON U.PostCount > 0 
WHERE 
    U.EngagementRank <= 10 AND 
    (P.ActivityRank <= 5 OR P.TotalBounties > 0)
ORDER BY 
    U.Reputation DESC, U.TotalViews DESC;
