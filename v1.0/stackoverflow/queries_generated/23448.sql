WITH UserReputation AS (
    SELECT Id, Reputation, 
           CASE 
               WHEN Reputation < 100 THEN 'Newbie'
               WHEN Reputation < 1000 THEN 'Intermediate'
               ELSE 'Expert' 
           END AS UserLevel
    FROM Users
),
PostDetails AS (
    SELECT p.*, 
           (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
           (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t WHERE t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])) AS AssociatedTags
    FROM Posts p
),
BadgesCount AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
ActiveUsers AS (
    SELECT u.Id, u.DisplayName, ur.Reputation, ur.UserLevel, COALESCE(bc.BadgeCount, 0) AS BadgeCount,
           COALESCE(SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END), 0) AS PositivePosts
    FROM Users u
    JOIN UserReputation ur ON u.Id = ur.Id
    LEFT JOIN BadgesCount bc ON u.Id = bc.UserId
    LEFT JOIN PostDetails p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 50
    GROUP BY u.Id, ur.Reputation, ur.UserLevel, bc.BadgeCount
),
PostHistoryDetails AS (
    SELECT ph.PostId, ph.UserId, ph.CreationDate, 
           pht.Name AS HistoryType, 
           ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevOrder,
           ph.Comment
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
)
SELECT au.DisplayName, au.Reputation, au.UserLevel, au.BadgeCount, au.PositivePosts, 
       p.Id AS PostId, p.Title, p.CommentCount, p.AssociatedTags,
       ph.UserDisplayName AS EditorName, ph.HistoryType, ph.CreationDate AS EditDate
FROM ActiveUsers au
JOIN PostDetails p ON p.OwnerUserId = au.Id
LEFT JOIN PostHistoryDetails ph ON p.Id = ph.PostId AND ph.RevOrder = 1
WHERE p.CreationDate >= current_date - INTERVAL '30 days'
ORDER BY au.Reputation DESC, p.ViewCount DESC;
