WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.ClosedDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVoteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenVoteCount,
        COUNT(*) AS TotalEdits
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.CreationDate, ph.UserDisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    ue.TotalPosts,
    ue.TotalViews,
    ue.TotalCommentScore,
    cph.CloseVoteCount,
    cph.ReopenVoteCount,
    CASE 
        WHEN rp.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN ue.TotalViews IS NULL THEN 'N/A'
        ELSE ROUND((rp.ViewCount::decimal / NULLIF(ue.TotalViews, 0)) * 100, 2) -- Engagement Percentage
    END AS EngagementPercentage
FROM RankedPosts rp
LEFT JOIN UserEngagement ue ON ue.UserId = rp.OwnerUserId
LEFT JOIN ClosedPostHistory cph ON cph.PostId = rp.PostId
WHERE rp.Rank <= 5 -- Top 5 posts per type
ORDER BY rp.CreationDate DESC, rp.Score DESC;
