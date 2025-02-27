WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Questions only

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
    WHERE 
        p.PostTypeId = 2  -- Answers only
),

UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9  -- BountyClose
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

PostActivity AS (
    SELECT 
        P.Id,
        P.Title,
        COALESCE(V.UpVotes, 0) AS TotalUpVotes,
        COALESCE(V.DownVotes, 0) AS TotalDownVotes,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId) V ON P.Id = V.PostId
),

TopUserPosts AS (
    SELECT 
        R.UserId,
        R.Title,
        R.TotalPosts,
        R.TotalComments,
        R.TotalBounty,
        PA.TotalUpVotes,
        PA.TotalDownVotes,
        PA.Score,
        DENSE_RANK() OVER (ORDER BY R.TotalBounty DESC) AS ReputationRank
    FROM 
        UserReputation R
    JOIN 
        PostActivity PA ON R.UserId = PA.OwnerUserId
    WHERE 
        R.TotalPosts > 0
)

SELECT 
    U.DisplayName,
    U.Reputation,
    PH.Level,
    PH.Title AS PostTitle,
    PH.Id AS PostId,
    T.TotalBounty,
    PA.TotalUpVotes,
    PA.TotalDownVotes,
    CASE
        WHEN PA.Score > 0 THEN 'Popular'
        WHEN PA.Score = 0 THEN 'Neutral'
        WHEN PA.Score < 0 THEN 'Not Popular'
    END AS PopularityStatus
FROM 
    RecursivePostHierarchy PH
JOIN 
    Posts P ON P.Id = PH.Id
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    UserReputation T ON U.Id = T.UserId
LEFT JOIN 
    PostActivity PA ON PA.Id = P.Id
WHERE 
    (P.ClosedDate IS NULL OR P.ClosedDate > CURRENT_TIMESTAMP)  -- Only active posts
    AND PA.PostRank <= 5  -- Limiting to top 5 recent posts per user
ORDER BY 
    U.Reputation DESC,
    PH.Level,
    PA.TotalUpVotes DESC;
