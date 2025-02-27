WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.Id, u.DisplayName
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEdited,
        STRING_AGG(CONCAT(ph.Comment, ': ', ph.Text), '; ') AS EditHistory
    FROM PostHistory ph
    GROUP BY ph.PostId
),
PostsStatistics AS (
    SELECT 
        ap.PostId,
        ap.Title,
        ap.OwnerDisplayName,
        ub.BadgeCount,
        ap.CommentCount,
        ap.UpVotes,
        ap.DownVotes,
        pha.LastEdited,
        pha.EditHistory
    FROM ActivePosts ap
    LEFT JOIN UserBadges ub ON ap.OwnerUserId = ub.UserId
    LEFT JOIN PostHistoryAnalysis pha ON ap.PostId = pha.PostId
)
SELECT 
    ps.Title,
    ps.OwnerDisplayName,
    ps.BadgeCount,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.LastEdited,
    ps.EditHistory
FROM PostsStatistics ps
WHERE ps.BadgeCount > 0
ORDER BY ps.UpVotes DESC, ps.CommentCount DESC;
