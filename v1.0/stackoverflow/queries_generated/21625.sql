WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        DisplayName, 
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank,
        CASE 
            WHEN Reputation IS NULL THEN 'No Reputation'
            WHEN Reputation < 100 THEN 'Newbie'
            WHEN Reputation BETWEEN 100 AND 500 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationCategory
    FROM Users
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(COUNT(ph.Id), 0) AS CloseCount
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    WHERE p.PostTypeId = 1 -- Questions only
    GROUP BY p.Id
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.Rank,
    u.ReputationCategory,
    pp.Title,
    pp.UpVotes,
    pp.DownVotes,
    cp.CloseCount AS NumberOfClosures,
    CASE 
        WHEN cp.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    -- This will return an arbitrary detail about a badge received by the user,
    -- even if the user has no badges (CROSS JOIN with a dummy value)
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM UserReputation u
LEFT JOIN PostVoteCounts pp ON u.UserId = pp.PostId
LEFT JOIN ClosedPosts cp ON pp.PostId = cp.PostId
LEFT JOIN Badges b ON u.Id = b.UserId
WHERE u.Reputation IS NOT NULL
AND EXISTS (
    SELECT 1 
    FROM Posts p
    WHERE p.OwnerUserId = u.UserId 
    AND p.CreatedAt > DATEADD(year, -1, GETDATE())
)
ORDER BY u.Reputation DESC, pp.UpVotes DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; -- Pagination logic

This SQL query performs a performance benchmark by integrating multiple constructs:

1. **CTEs**: The use of Common Table Expressions (CTEs) to organize intermediate results.
2. **Window Functions**: Utilizing window functions to rank users based on their reputation.
3. **Outer Joins**: LEFT JOINs are implemented to include users even when they have no associated posts or votes.
4. **Subqueries**: Correlated subqueries are used in the `EXISTS` clause to filter users based on their activity.
5. **Aggregations**: Aggregations and conditional sums are employed to count vote types.
6. **COALESCE and NULL Logic**: COALESCE is used to handle NULLs gracefully for badge names and closure counts.
7. **Complex Predicate**: Utilizing complex conditions for filtering users based on various parameters.

This query is designed to extract a wealth of information while demonstrating various SQL features in practice.
