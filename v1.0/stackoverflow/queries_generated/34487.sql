WITH RECURSIVE UserHierarchy AS (
    SELECT U.Id, U.DisplayName, U.Reputation, U.CreationDate, 1 AS Level
    FROM Users U
    WHERE U.Reputation >= (SELECT AVG(Reputation) FROM Users)  -- Start from users with above average reputation

    UNION ALL

    SELECT U.Id, U.DisplayName, U.Reputation, U.CreationDate, UH.Level + 1
    FROM Users U
    JOIN UserHierarchy UH ON U.Id = U.Id  -- Recursive join to self to establish hierarchy (mock example; replace logic appropriately)
    WHERE UH.Level < 5  -- Limit the hierarchy depth
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS PostCount,
    SUM(V.BountyAmount) AS TotalBounty,
    AVG(CASE WHEN C.Score IS NULL THEN 0 ELSE C.Score END) AS AvgCommentScore,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
    ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(V.BountyAmount) DESC) AS RankByBounty,
    RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN Votes V ON P.Id = V.PostId
LEFT JOIN Comments C ON P.Id = C.PostId
LEFT JOIN LATERAL (
    SELECT string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><') AS TagName
) AS T ON TRUE
WHERE U.CreationDate > CURRENT_DATE - INTERVAL '5 years'  -- Only considering users created within the last 5 years
GROUP BY U.Id
HAVING COUNT(DISTINCT P.Id) > 0  -- Users must have posts
ORDER BY U.Reputation DESC, TotalBounty DESC, PostCount DESC
LIMIT 100;  -- Limit to top 100 users based on the criteria
