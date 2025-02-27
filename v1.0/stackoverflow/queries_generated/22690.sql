WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostsCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        A.DisplayName AS AcceptedAnswer,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COALESCE(SUM(VB.BountyAmount), 0) AS TotalBountyAmount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.AcceptedAnswerId = A.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes VB ON P.Id = VB.PostId AND VB.VoteTypeId = 9  -- BountyClose
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, A.DisplayName
),
FinalReport AS (
    SELECT 
        U.UserId,
        U.DisplayName AS UserDisplayName,
        PA.PostId,
        PA.AcceptedAnswer,
        PA.CommentCount,
        PA.TotalBountyAmount,
        U.UpVotesCount,
        U.DownVotesCount,
        (CASE WHEN U.PostsCount > 0 THEN CAST(U.UpVotesCount AS FLOAT) / NULLIF(U.PostsCount, 0) ELSE 0 END) AS AverageUpVotesPerPost,
        (CASE WHEN U.PostsCount > 0 THEN CAST(U.DownVotesCount AS FLOAT) / NULLIF(U.PostsCount, 0) ELSE 0 END) AS AverageDownVotesPerPost
    FROM 
        UserActivity U
    INNER JOIN 
        PostStatistics PA ON U.UserId = PA.PostId
)
SELECT 
    FR.*,
    CASE 
        WHEN FR.TotalBountyAmount = 0 THEN 'No Bounty Awarded' 
        WHEN FR.TotalBountyAmount > 100 THEN 'High Bounty Awarded'
        ELSE 'Standard Bounty Awarded' 
    END AS BountyStatus,
    CASE
        WHEN FR.CommentCount > 10 THEN 'Highly Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM 
    FinalReport FR
ORDER BY 
    FR.UserDisplayName ASC, FR.CommentCount DESC;
