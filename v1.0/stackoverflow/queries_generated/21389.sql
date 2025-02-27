WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        ub.BadgeNames,
        ub.BadgeCount
    FROM RankedPosts rp
    LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.CommentCount,
    pm.UpVoteCount,
    pm.DownVoteCount,
    COALESCE(pm.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(pm.BadgeCount, 0) AS BadgeCount,
    CASE
        WHEN pm.DownVoteCount > pm.UpVoteCount THEN 'More Negative'
        WHEN pm.UpVoteCount > pm.DownVoteCount THEN 'More Positive'
        ELSE 'Neutral'
    END AS VoteSentiment,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pm.PostId) AS TotalComments,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Posts p WHERE p.AcceptedAnswerId = pm.PostId) THEN 'Has Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AcceptedAnswerStatus,
    CONCAT('Post ID: ', pm.PostId, ' | Created on: ', TO_CHAR(pm.CreationDate, 'YYYY-MM-DD HH24:MI:SS')) AS PostInfo
FROM PostMetrics pm
WHERE pm.CommentCount >= (SELECT AVG(CommentCount) FROM RankedPosts) -- Higher than average
AND pm.CreationDate >= NOW() - INTERVAL '30 days' -- Only recent posts
ORDER BY pm.UpVoteCount DESC, pm.CommentCount DESC
LIMIT 10;
