
WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate, DisplayName, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
), ActivePosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, 
           u.DisplayName AS OwnerDisplayName,
           COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
           COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= CAST('2024-10-01' AS DATE) - 30
), HotTopics AS (
    SELECT Tags, COUNT(*) AS TopicCount
    FROM Posts
    WHERE Tags IS NOT NULL
    GROUP BY Tags
    HAVING COUNT(*) >= 5
), PostHistoryStats AS (
    SELECT ph.PostId, 
           MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
           MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate,
           COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS SuggestionAppliedCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT up.DisplayName AS UserDisplayName, 
       up.Reputation, 
       up.Rank, 
       ap.Title AS PostTitle, 
       ap.ViewCount, 
       ap.Score, 
       ap.CommentCount, 
       ht.TopicCount AS PopularTags,
       phs.LastClosedDate, 
       phs.LastReopenedDate, 
       phs.SuggestionAppliedCount
FROM UserReputation up
INNER JOIN ActivePosts ap ON ap.OwnerDisplayName = up.DisplayName
LEFT JOIN HotTopics ht ON ht.Tags LIKE '%' + (SELECT STRING_AGG(Tags, ',') FROM (SELECT DISTINCT TOP 3 Tags FROM Posts)) + '%'
LEFT JOIN PostHistoryStats phs ON phs.PostId = ap.Id
WHERE up.Reputation > 100 AND phs.LastClosedDate IS NULL
ORDER BY up.Rank DESC, ap.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
