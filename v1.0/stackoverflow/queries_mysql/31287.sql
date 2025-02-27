
WITH RECURSIVE UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COALESCE(uh.TotalPosts, 0) AS UserTotalPosts,
        COALESCE(uh.TotalQuestions, 0) AS UserTotalQuestions,
        COALESCE(uh.TotalAnswers, 0) AS UserTotalAnswers,
        COALESCE(uh.TotalScore, 0) AS UserTotalScore
    FROM Posts p
    LEFT JOIN UserPosts uh ON p.OwnerUserId = uh.UserId
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        GROUP_CONCAT(DISTINCT cr.Name ORDER BY cr.Name SEPARATOR ', ') AS ClosureReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON CAST(ph.Comment AS UNSIGNED) = cr.Id
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.PostId, ph.CreationDate
),
RankedPosts AS (
    SELECT 
        ps.*,
        @rank := IF(@prev_score = ps.Score, @rank, @rank + 1) AS PostRank,
        @prev_score := ps.Score
    FROM PostStats ps, (SELECT @rank := 0, @prev_score := NULL) AS vars
    ORDER BY ps.Score DESC, ps.ViewCount DESC
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UserTotalPosts,
    rp.UserTotalQuestions,
    rp.UserTotalAnswers,
    rp.UserTotalScore,
    cp.ClosureReasons
FROM RankedPosts rp
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE rp.PostRank <= 10 
ORDER BY rp.Score DESC, rp.ViewCount DESC;
