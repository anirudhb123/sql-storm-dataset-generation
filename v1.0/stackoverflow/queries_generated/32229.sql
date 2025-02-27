WITH RecursivePostCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.PostTypeId,
        P.AcceptedAnswerId,
        P.CreationDate,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Filtering for questions as the root level

    UNION ALL

    SELECT 
        P2.Id,
        P2.Title,
        P2.OwnerUserId,
        P2.PostTypeId,
        P2.AcceptedAnswerId,
        P2.CreationDate,
        C.Level + 1
    FROM 
        Posts P2
    INNER JOIN 
        RecursivePostCTE C ON P2.ParentId = C.PostId
    WHERE 
        P2.PostTypeId = 2  -- Selecting answers
),

UserStats AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.Reputation > 100  -- Filtering users with high reputation
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),

PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        PostId
)

SELECT 
    R.PostId,
    R.Title,
    U.DisplayName AS Owner,
    COALESCE(PS.UpVotes, 0) AS TotalUpVotes,
    COALESCE(PS.DownVotes, 0) AS TotalDownVotes,
    COALESCE(PS.TotalVotes, 0) AS TotalVotes,
    R.CreationDate,
    R.Level,
    U.Reputation AS OwnerReputation,
    U.TotalPosts,
    U.TotalAnswers,
    U.TotalComments
FROM 
    RecursivePostCTE R
LEFT JOIN 
    UserStats U ON R.OwnerUserId = U.Id
LEFT JOIN 
    PostVoteStats PS ON R.PostId = PS.PostId
WHERE 
    R.Level = 1  -- Retrieve only the top-level questions
ORDER BY 
    U.Reputation DESC,  -- Ordering by user's reputation
    R.CreationDate DESC  -- Then by the post date
LIMIT 100;  -- Limiting to the top 100 results

