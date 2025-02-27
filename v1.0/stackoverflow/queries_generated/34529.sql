WITH RecursivePostHierarchy AS (
    SELECT p.Id AS PostId, p.ParentId, p.Title, p.CreationDate, 
           ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate) AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL
    
    UNION ALL
    
    SELECT p.Id AS PostId, p.ParentId, p.Title, p.CreationDate, 
           r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputation AS (
    SELECT U.Id, U.DisplayName, U.Reputation, 
           COUNT(DISTINCT P.Id) AS PostCount,
           SUM(V.BountyAmount) AS TotalBounty 
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)
    GROUP BY U.Id
),
PopularTags AS (
    SELECT Tags.TagName, COUNT(P.Id) AS PostCount
    FROM Posts P
    CROSS JOIN UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '>')) AS Tags(TagName)
    GROUP BY Tags.TagName
    HAVING COUNT(P.Id) > 10
)
SELECT R.PostId, R.Title, U.DisplayName, U.Reputation,
       COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
       COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
       PT.TotalBounty, T.PostCount AS PopularTagCount, R.Level
FROM RecursivePostHierarchy R
JOIN Users U ON R.OwnerUserId = U.Id
LEFT JOIN Votes V ON R.PostId = V.PostId
LEFT JOIN UserReputation PT ON U.Id = PT.Id
LEFT JOIN PopularTags T ON T.TagName IN (SELECT UNNEST(string_to_array(substring(R.Tags, 2, length(R.Tags)-2), '>')))
                                      WHERE R.Tags IS NOT NULL)
WHERE R.Level = 1 AND U.Reputation > 1000
GROUP BY R.PostId, R.Title, U.DisplayName, U.Reputation, PT.TotalBounty, T.PostCount, R.Level
ORDER BY R.CreationDate DESC
LIMIT 50;
