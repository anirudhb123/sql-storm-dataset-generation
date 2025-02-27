WITH RecursiveCTE AS (
    -- Recursive CTE to find the hierarchy of posts and their accepted answers
    SELECT 
        p.Id AS PostId,
        COALESCE(a.Id, -1) AS AcceptedAnswerId,
        1 AS Level
    FROM Posts p
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id
    WHERE p.PostTypeId = 1 -- Only Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        COALESCE(a.Id, -1) AS AcceptedAnswerId,
        Level + 1
    FROM Posts p
    INNER JOIN RecursiveCTE r ON p.ParentId = r.PostId -- Joining back to find answers to answers
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id
)

SELECT 
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
    AVG(DATEDIFF(COALESCE(p.LastEditDate, p.CreationDate), p.CreationDate)) AS AvgPostEditDuration,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
    COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenCount
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 -- BountyClose
LEFT JOIN Tags t ON t.Id IN (SELECT unnest(string_to_array(p.Tags, ','))::int) -- Unnest tags
LEFT JOIN PostHistory ph ON p.Id = ph.PostId
WHERE u.Reputation > 1000 -- Only include users with high reputation
GROUP BY u.Id, u.DisplayName, u.Reputation
HAVING COUNT(DISTINCT p.Id) > 10 -- Filter for users with more than 10 posts
ORDER BY AvgPostEditDuration DESC, TotalPosts DESC
FETCH FIRST 10 ROWS ONLY; -- Limit the results for performance benchmarking
