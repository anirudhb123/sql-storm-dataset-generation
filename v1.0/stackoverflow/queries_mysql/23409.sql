
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(NULLIF(UPPER(p.Title), ''), 'Untitled') AS SafeTitle
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        GROUP_CONCAT(DISTINCT CONCAT(cr.Name, ': ', ph.Comment) SEPARATOR '; ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON CAST(ph.Comment AS UNSIGNED) = cr.Id
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.PostId
)
SELECT 
    r.PostId,
    r.SafeTitle,
    r.CreationDate,
    r.ViewCount,
    u.DisplayName,
    us.TotalPosts,
    us.TotalAnswers,
    us.TotalQuestions,
    COALESCE(c.CloseCount, 0) AS CloseCount,
    COALESCE(c.CloseReasons, 'No reasons provided') AS CloseReasons
FROM RankedPosts r
JOIN Users u ON r.PostTypeId = 1 AND u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = r.PostId)
JOIN UserPostStats us ON u.Id = us.UserId
LEFT JOIN ClosedPosts c ON r.PostId = c.PostId
WHERE r.Rank <= 5
ORDER BY r.ViewCount DESC, CloseCount DESC
LIMIT 10 OFFSET 0;
