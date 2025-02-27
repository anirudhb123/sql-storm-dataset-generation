WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostScore AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS NetScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS LinkedPostsCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    GROUP BY p.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LatestChangeDate,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 25) AS TweetedCount
    FROM PostHistory ph
    GROUP BY ph.PostId
),
Metrics AS (
    SELECT 
        ps.PostId,
        ps.NetScore,
        ps.CommentCount,
        ps.LinkedPostsCount,
        COALESCE(pgs.CloseReopenCount, 0) AS CloseReopenCount,
        COALESCE(pgs.TweetedCount, 0) AS TweetedCount,
        ROW_NUMBER() OVER (ORDER BY ps.NetScore DESC) AS Rank
    FROM PostScore ps
    LEFT JOIN PostHistoryStats pgs ON ps.PostId = pgs.PostId
)
SELECT 
    u.DisplayName,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    m.PostId,
    m.NetScore,
    m.CommentCount,
    m.LinkedPostsCount,
    m.CloseReopenCount,
    m.TweetedCount,
    CASE 
        WHEN m.Rank <= 10 THEN 'Top Post'
        ELSE 'Regular Post' 
    END AS PostCategory
FROM Metrics m 
JOIN UserBadges ub ON m.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ub.UserId)
JOIN Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = m.PostId)
WHERE ub.GoldBadges > 0 
    OR ub.SilverBadges > 1 
    OR (ub.BronzeBadges IS NOT NULL AND ub.BronzeBadges >= 2)
ORDER BY u.DisplayName ASC, m.NetScore DESC;
