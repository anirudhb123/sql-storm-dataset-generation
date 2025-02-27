-- Performance benchmarking query to analyze user activity and post engagement

WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    UserId,
    DisplayName,
    PostCount,
    CommentCount,
    UpVotes,
    DownVotes,
    TotalViews,
    TotalScore,
    LastPostDate
FROM 
    UserEngagement
ORDER BY 
    PostCount DESC, TotalScore DESC
LIMIT 10;
