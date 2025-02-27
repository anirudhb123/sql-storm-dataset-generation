WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotesCount, -- Count of upvotes (VoteTypeId = 2)
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotesCount, -- Count of downvotes (VoteTypeId = 3
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 0 -- Only users with positive reputation
    GROUP BY u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Closed and reopened
    GROUP BY ph.PostId
),
TopTags AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(pt.PostId) AS Count
    FROM Tags t
    LEFT JOIN Posts pt ON pt.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY t.Id, t.TagName
    HAVING COUNT(pt.PostId) > 0
),
UserPostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditedDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 5 -- Edit Body
    GROUP BY p.Id, p.OwnerUserId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    COALESCE(cp.CloseCount, 0) AS TotalCloseActions,
    COALESCE(SUM(DISTINCT t.Count), 0) AS TotalTags,
    COALESCE(up.UpVotesCount, 0) - COALESCE(up.DownVotesCount, 0) AS NetVotes,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Latest Post'
        WHEN rp.PostRank > 1 THEN 'Earlier Post'
        ELSE 'No Posts'
    END AS PostRankStatus,
    CASE 
        WHEN ui.CommentCount IS NULL THEN 'No Comments'
        ELSE CONCAT('Comments: ', ui.CommentCount)
    END AS CommentInfo,
    CASE 
        WHEN ui.LastEditedDate IS NOT NULL THEN 
            CONCAT('Edited On: ', to_char(ui.LastEditedDate, 'YYYY-MM-DD HH24:MI:SS'))
        ELSE 'Not Edited'
    END AS LastEditedInfo
FROM RankedPosts rp
JOIN UserStats us ON rp.PostId = us.UserId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN TopTags t ON rp.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE CONCAT('%<', t.TagName, '>%'))
LEFT JOIN UserPostInfo ui ON rp.PostId = ui.PostId
GROUP BY us.DisplayName, us.Reputation, rp.Title, rp.CreationDate, rp.ViewCount, cp.CloseCount, rp.PostRank, ui.CommentCount, ui.LastEditedDate
ORDER BY us.Reputation DESC, rp.CreationDate DESC
LIMIT 100;
