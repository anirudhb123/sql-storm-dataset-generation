WITH RecentPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           p.PostTypeId, 
           p.Score,
           RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) as PostRank
    FROM Posts p 
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
),
TopUsers AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           SUM(COALESCE(v.VoteTypeId = 2, 0) * 1) AS UpVotes,   -- Count of upvotes
           SUM(COALESCE(v.VoteTypeId = 3, 0) * -1) AS DownVotes  -- Count of downvotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT ph.PostId,
           ph.PostHistoryTypeId,
           ph.UserId, 
           ph.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM PostHistory ph
    WHERE ph.CreationDate >= NOW() - INTERVAL '1 year'
),
MostEditedPosts AS (
    SELECT ph.PostId,
           COUNT(*) AS EditCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
    GROUP BY ph.PostId
    HAVING COUNT(*) > 10
),
UserBadges AS (
    SELECT b.UserId, 
           COUNT(*) AS BadgeCount 
    FROM Badges b
    GROUP BY b.UserId
)

SELECT DISTINCT p.Id AS PostId,
                p.Title,
                p.CreationDate,
                p.Score,
                ph.UserDisplayName AS LastEditor,
                COALESCE(pb.BadgeCount, 0) AS TotalBadges,
                up.UpVotes,
                down.DownVotes,
                pht.Name AS LastActionType,
                CASE 
                    WHEN RecentPosts.PostRank <= 3 THEN 'New'
                    ELSE 'Archived'
                END AS PostStatus,
                CASE 
                    WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
                    ELSE 'Other'
                END AS ClosureStatus,
                -- Add bizarre logic: if Post is older than 1 year and has more than 5 edits, mark as "Veteran"
                CASE 
                    WHEN p.CreationDate < (CURRENT_DATE - INTERVAL '1 year') AND 
                         (SELECT COUNT(*) FROM MostEditedPosts ep WHERE ep.PostId = p.Id) > 5
                    THEN 'Veteran'
                    ELSE 'Regular'
                END AS PostTypeRank
FROM Posts p
LEFT JOIN PostHistoryDetails phd ON p.Id = phd.PostId AND phd.HistoryRank = 1
LEFT JOIN Users ph ON ph.Id = phd.UserId
LEFT JOIN UserBadges pb ON pb.UserId = ph.Id
LEFT JOIN TopUsers up ON up.UserId = p.OwnerUserId
LEFT JOIN TopUsers down ON down.UserId = p.LastEditorUserId
LEFT JOIN PostHistoryTypes pht ON pht.Id = phd.PostHistoryTypeId
LEFT JOIN RecentPosts ON p.Id = RecentPosts.Id
LEFT JOIN MostEditedPosts mep ON p.Id = mep.PostId
WHERE p.PostTypeId = 1  -- Only Questions
ORDER BY p.CreationDate DESC, p.Score DESC
LIMIT 100;
