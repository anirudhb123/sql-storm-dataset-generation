WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.DisplayName,
        0 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
    
    UNION ALL
    
    SELECT 
        U.Id,
        U.Reputation,
        U.CreationDate,
        U.DisplayName,
        UR.Level + 1
    FROM 
        Users U
    INNER JOIN 
        UserReputation UR ON U.Reputation < UR.Reputation
)

SELECT 
    R.UserId,
    R.DisplayName,
    R.Reputation,
    R.CreationDate,
    COALESCE(V.TotalVotes, 0) AS TotalVotes,
    COALESCE(P.PostCount, 0) AS PostCount,
    CASE 
        WHEN R.Reputation >= 20000 THEN 'Elite'
        WHEN R.Reputation >= 10000 THEN 'Pro'
        WHEN R.Reputation >= 5000 THEN 'Intermediate'
        ELSE 'Beginner'
    END AS UserLevel,
    STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed
FROM 
    UserReputation R
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(Id) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        UserId
) V ON R.UserId = V.UserId
LEFT JOIN (
    SELECT 
        OwnerUserId,
        COUNT(Id) AS PostCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
) P ON R.UserId = P.OwnerUserId
LEFT JOIN (
    SELECT 
        P.Tags,
        T.TagName
    FROM 
        Posts P
    CROSS JOIN 
        LATERAL unnest(string_to_array(trim(both '{}' from P.Tags), '><')) AS TagName
    JOIN 
        Tags T ON trim(both ' ' from TagName) = T.TagName
) T ON R.UserId IN (
    SELECT DISTINCT 
        OwnerUserId 
    FROM 
        Posts 
    WHERE 
        Tags IS NOT NULL
)
WHERE 
    R.Level < 3
GROUP BY 
    R.UserId, R.DisplayName, R.Reputation, R.CreationDate, V.TotalVotes, P.PostCount
ORDER BY 
    R.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
