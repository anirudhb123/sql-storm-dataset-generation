WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        (COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) - COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3)) AS VoteBalance
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3) AS Score
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END) AS LastDeletedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 6 THEN 1 END) AS TagChanges
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeList,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    up.UserId,
    u.DisplayName,
    up.UpVoteCount,
    up.DownVoteCount,
    up.VoteBalance,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.CommentCount AS RecentPostComments,
    pha.LastClosedDate,
    pha.LastReopenedDate,
    pha.LastDeletedDate,
    pha.TagChanges,
    ub.BadgeList,
    ub.BadgeCount,
    ub.LastBadgeDate
FROM 
    UserVoteCounts up
INNER JOIN 
    RecentPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistoryAnalysis pha ON rp.PostId = pha.PostId
LEFT JOIN 
    UserBadges ub ON up.UserId = ub.UserId
WHERE 
    (up.VoteBalance > 0 OR rp.CommentCount > 0)
    AND (rp.CommentCount IS NOT NULL OR pha.LastClosedDate IS NOT NULL)
ORDER BY 
    up.VoteBalance DESC, rp.CreationDate DESC
LIMIT 100;

This SQL query performs multiple complex operations including:
1. **CTEs** to summarize user votes, gather recent posts, analyze post history, and collect user badge information.
2. **LEFT JOINs** to ensure that all relevant data is collected, even if some entries do not exist in related tables.
3. A combination of conditional aggregation and filtering using SQL window functions, enabling nuanced analysis of users and their posts.
4. It deals with NULL logic to ensure that the results are meaningful for posts that may or may not have comments or history entries.
5. The query concludes with a ranking based on user vote balances and recent activity, presenting an intriguing snapshot of user engagement within a specified timeframe.
