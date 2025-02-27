WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        PostCount,
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    R.DisplayName,
    R.Reputation,
    R.UpVotes,
    R.DownVotes,
    R.PostCount,
    R.CommentCount,
    COALESCE(NULLIF(R.UpVotes - R.DownVotes, 0), 'No Votes') AS VoteDifference,
    CASE 
        WHEN R.CommentCount = 0 THEN 'No Comments'
        ELSE CAST(R.CommentCount AS VARCHAR)
    END AS CommentStatus
FROM 
    RankedUsers R
WHERE 
    R.UserRank <= 10 
ORDER BY 
    R.Reputation DESC;

-- Additional segment with various constructs
SELECT 
    P.Title,
    COUNT(C.Id) AS TotalComments,
    MAX(V.CreationDate) AS LastVoteDate
FROM 
    Posts P
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 
    P.Title
HAVING 
    COUNT(C.Id) > 5 AND MAX(V.CreationDate) IS NOT NULL
ORDER BY 
    TotalComments DESC;

-- Union to display users and their activity alongside specific post statistics
SELECT 
    U.DisplayName, 
    U.Reputation, 
    'User Activity' AS ActivityType 
FROM 
    Users U 
UNION ALL 
SELECT 
    B.Name, 
    COUNT(P.Id), 
    'Badge Awarded' AS ActivityType 
FROM 
    Badges B 
LEFT JOIN 
    Users U ON B.UserId = U.Id
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    B.Name;
