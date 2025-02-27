WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9 -- BountyClose votes
    GROUP BY 
        U.Id, U.Reputation
), PostActivity AS (
    SELECT 
        P.Id AS PostId,
        CASE 
            WHEN P.CloseReasonId IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus,
        COUNT(C) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS HistoryCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.CloseReasonId
), UserPostRanking AS (
    SELECT 
        U.UserId,
        U.Reputation,
        U.TotalPosts,
        U.Questions,
        U.Answers,
        U.TotalBounty,
        P.PostId,
        P.PostStatus,
        P.CommentCount,
        P.HistoryCount,
        RANK() OVER (PARTITION BY U.UserId ORDER BY U.Reputation DESC, P.CommentCount DESC) AS Rank
    FROM 
        UserStatistics U
    JOIN 
        PostActivity P ON U.TotalPosts > 0 -- Only include users with posts
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    COALESCE(B.Class, 0) AS BadgeClass,
    U.TotalBounty,
    R.PostStatus,
    R.CommentCount,
    R.HistoryCount,
    CASE 
        WHEN R.Rank = 1 THEN 'Top Performer'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM 
    Users U
LEFT JOIN 
    Badges B ON U.Id = B.UserId AND B.Class = 1 -- Gold badges only
JOIN 
    UserPostRanking R ON U.Id = R.UserId
WHERE 
    U.Reputation IS NOT NULL 
    AND U.CreationDate < CURRENT_DATE - INTERVAL '1 year' -- Filter users created over a year ago
ORDER BY 
    U.Reputation DESC, 
    R.CommentCount DESC;

