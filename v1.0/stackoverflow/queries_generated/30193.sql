WITH RECURSIVE UserReputationCTE AS (
    -- Base case: Retrieve users with their reputations
    SELECT Id, Reputation, CreationDate, DisplayName
    FROM Users
    WHERE Reputation > 0
    
    UNION ALL
    
    -- Recursive case: Get incremental reputation changes
    SELECT u.Id, u.Reputation + 10 AS Reputation, u.CreationDate, u.DisplayName
    FROM Users u
    JOIN UserReputationCTE ur ON ur.Id = u.Id
    WHERE u.Reputation < 10000  -- Assuming we want reputations up to a limit
),
PostWithDetails AS (
    -- Get detailed post data including user who created it
    SELECT p.Id, p.Title, p.CreationDate, p.ViewCount, 
           p.Score, p.AcceptedAnswerId, 
           COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
           COUNT(c.Id) AS CommentCount,
           COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
           COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
           MAX(b.Name) AS BadgeName
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    LEFT JOIN Badges b ON b.UserId = u.Id AND b.Date = (
        SELECT MAX(Date) FROM Badges WHERE UserId = u.Id
    )
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, u.DisplayName
),
PostHistoryInfo AS (
    -- Get history information of posts with more complex predicates and joins
    SELECT ph.PostId,
           STRING_AGG(CONCAT_WS(': ', pht.Name, ph.CreationDate::text), '; ') AS HistoryLog,
           COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE ph.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY ph.PostId
),
Results AS (
    -- Merge post details and history information
    SELECT pd.Id AS PostId, pd.Title, pd.OwnerDisplayName, pd.ViewCount, 
           pd.Score, pd.CommentCount, pd.UpVotes, pd.DownVotes,
           COALESCE(ph.HistoryLog, 'No history available') AS HistoryLog,
           ph.CloseCount
    FROM PostWithDetails pd
    LEFT JOIN PostHistoryInfo ph ON pd.Id = ph.PostId
)
SELECT r.*, 
       ROW_NUMBER() OVER (ORDER BY r.ViewCount DESC) AS Rank,
       CASE 
           WHEN r.CloseCount > 0 THEN 'Closed'
           ELSE 'Open'
       END AS PostStatus
FROM Results r
WHERE r.Score > 5 -- Arbitrary score filter for high-quality posts
ORDER BY r.Rank;
