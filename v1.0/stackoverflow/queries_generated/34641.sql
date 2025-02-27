WITH RecursiveUserScore AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        1 AS Level
    FROM 
        Users U

    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation + (CASE 
                            WHEN PH.PostId IS NOT NULL THEN 10 
                            ELSE 0 
                         END) AS Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        R.Level + 1
    FROM 
        RecursiveUserScore R
    LEFT JOIN Votes V ON V.UserId = R.Id
    LEFT JOIN Posts P ON P.Id = V.PostId 
    LEFT JOIN PostHistory PH ON PH.UserId = R.Id AND PH.CreationDate >= U.CreationDate
    WHERE 
        R.Level < 5 -- limit recursion for performance
)

SELECT 
    U.Id,
    U.DisplayName,
    U.Reputation,
    COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    COUNT(DISTINCT C.Id) AS CommentCount,
    COUNT(DISTINCT P.Id) AS PostCount,
    MAX(R.Level) AS UserLevel,
    STRING_AGG(DISTINCT T.TagName, ',') AS TagsUsed
FROM 
    Users U
LEFT JOIN Votes V ON V.UserId = U.Id
LEFT JOIN Comments C ON C.UserId = U.Id
LEFT JOIN Posts P ON P.OwnerUserId = U.Id
LEFT JOIN LATERAL (
    SELECT 
        T.TagName
    FROM 
        UNNEST(string_to_array(P.Tags, '><')) AS T(TagName) 
) T ON TRUE
LEFT JOIN RecursiveUserScore R ON R.Id = U.Id
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
HAVING 
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) > 0 
    OR SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) > 0
ORDER BY 
    U.Reputation DESC 
LIMIT 100;

-- For performance benchmarking, you might want to examine:
-- 1. Execution Plan
-- 2. Timing for this query
-- 3. Resource usage and optimization results
