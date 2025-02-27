WITH RecursiveTagHierarchy AS (
    SELECT 
        T.Id,
        T.TagName,
        T.Count,
        1 AS Level
    FROM 
        Tags T
    WHERE 
        T.IsModeratorOnly = 0
    
    UNION ALL
    
    SELECT 
        T.Id,
        T.TagName,
        T.Count,
        R.Level + 1
    FROM 
        Tags T
    INNER JOIN 
        RecursiveTagHierarchy R ON T.ExcerptPostId = R.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVoteCount,
        SUM(V.VoteTypeId = 3) AS DownVoteCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        P.Id, P.OwnerUserId, P.Title, P.CreationDate
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.PostId) AS TotalPosts,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(P.UpVoteCount, 0)) AS TotalUpVotes,
        SUM(COALESCE(P.DownVoteCount, 0)) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        PostStats P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 50
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)
SELECT 
    U.Id,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpVotes,
    U.TotalDownVotes,
    COALESCE(TH.TagName, 'No Tags') AS MostRelevantTag,
    CASE 
        WHEN U.TotalPosts > 10 THEN 'Experienced'
        WHEN U.TotalPosts BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Novice'
    END AS UserCategory
FROM 
    UserPerformance U
LEFT JOIN 
    RecursiveTagHierarchy TH ON U.UserId = TH.Id
WHERE 
    U.TotalPosts > 0
ORDER BY 
    U.Reputation DESC, U.TotalUpVotes DESC
OPTION (MAXRECURSION 100);
