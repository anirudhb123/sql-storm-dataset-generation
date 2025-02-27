WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(count(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year' AND p.Deleted IS NULL
    GROUP BY p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        CASE 
            WHEN ps.UpVoteCount - ps.DownVoteCount > 0 THEN 'Positive'
            WHEN ps.UpVoteCount - ps.DownVoteCount < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment,
        DENSE_RANK() OVER (ORDER BY ps.ViewCount DESC) AS PostRank
    FROM PostStats ps
)
SELECT 
    up.UserId,
    up.DisplayName,
    COALESCE(rp.PostId, -1) AS MostViewedPostId,
    COALESCE(rp.Title, 'No Posts') AS MostViewedPostTitle,
    COALESCE(rp.CommentCount, 0) AS MostViewedPostCommentCount,
    COALESCE(up.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(up.TotalBounty, 0) AS UserTotalBounty,
    CASE 
        WHEN up.TotalBounty IS NULL THEN 'No Bounty'
        WHEN up.TotalBounty > 100 THEN 'High Bounty'
        ELSE 'Low Bounty'
    END AS BountyStatus
FROM UserStats up
LEFT JOIN RankedPosts rp ON up.UserId = (
    SELECT OwnerUserId 
    FROM Posts 
    WHERE Id = rp.PostId
    LIMIT 1
)
WHERE up.BadgeCount > 0 OR up.TotalBounty > 0
ORDER BY up.UserBadgeCount DESC, up.TotalBounty DESC, rp.PostRank
FETCH FIRST 10 ROWS ONLY;

-- Aggregated results based on conditions
SELECT 
    p.Id, 
    p.Title,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes,
    MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate ELSE NULL END) AS LastClosedDate,
    MAX(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN ph.CreationDate ELSE NULL END) AS LastDeletedDate
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN PostHistory ph ON p.Id = ph.PostId
WHERE p.PostTypeId IN (1, 2)  -- Only questions and answers
GROUP BY p.Id
HAVING COUNT(DISTINCT c.Id) > 5 -- More than 5 comments
ORDER BY UpVotes DESC, DownVotes DESC;
