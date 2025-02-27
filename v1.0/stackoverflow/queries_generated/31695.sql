WITH RECURSIVE UserReputation AS (
    SELECT 
        Id, 
        Reputation, 
        CreationDate,
        DisplayName,
        CAST(CAST(Reputation AS VARCHAR) + ' points for ' + DisplayName AS VARCHAR) AS ReputationInfo,
        1 AS Level
    FROM Users
    WHERE Reputation > 0
    
    UNION ALL
    
    SELECT 
        u.Id, 
        u.Reputation, 
        u.CreationDate,
        u.DisplayName,
        CAST(ur.ReputationInfo || ', ' || CAST(u.Reputation AS VARCHAR) || ' points for ' || u.DisplayName AS VARCHAR),
        ur.Level + 1
    FROM Users u
    JOIN UserReputation ur ON u.Reputation > ur.Reputation
)
, PostAggregate AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Only consider BountyStart and BountyClose
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
)
SELECT 
    u.DisplayName,
    u.Reputation AS UserReputation,
    GROUP_CONCAT(DISTINCT t.TagName) AS TagsUsed,
    pa.PostId,
    pa.Title,
    pa.ViewCount,
    pa.CommentCount,
    pa.TotalBounty
FROM Users u
JOIN UserReputation ur ON u.Id = ur.Id
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[]) 
LEFT JOIN PostAggregate pa ON p.Id = pa.PostId
WHERE u.Reputation >= 100
GROUP BY u.Id, pa.PostId
HAVING COUNT(DISTINCT t.TagName) > 3 
ORDER BY UserReputation DESC, pa.ViewCount DESC 
LIMIT 100;

### Explanation:
1. **CTE for Recursive Reputation Calculation**: The `UserReputation` common table expression recursively aggregates and constructs a string representing user reputations for users who have positive reputations.

2. **Aggregating Post Data**: The `PostAggregate` CTE is used to summarize posts created in the last year, counting comments and summing up bounties.

3. **Final Query**: The final selection combines users with their reputation and the posts they owned, filtering for users with a reputation of at least 100 and aggregating tag usage to filter for those that have used more than three different tags. 

4. **Distinct Tags**: The use of `DISTINCT` within `GROUP_CONCAT` to list all unique tags associated with the posts owned by the user.

5. **Ordering and Limiting**: The results are ordered by reputation and views, limiting to the top 100 records.
