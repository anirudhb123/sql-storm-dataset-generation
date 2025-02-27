WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty,
        COALESCE(SUM(v.UserId IS NOT NULL), 0) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(v.BountyAmount) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        LEAD(CreationDate, 1) OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate) AS NextPostDate
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        pt.Name AS PostTypeName,
        COALESCE(c.CloseReasonId, 'Not Closed') AS CloseReason
    FROM PostHistory ph
    LEFT JOIN CloseReasonTypes c ON ph.Comment::int = c.Id
    JOIN PostTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE ph.CreationDate >= NOW() - INTERVAL '6 months'
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.TotalBounty,
    us.VoteCount,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.ViewCount AS RecentPostViews,
    rp.NextPostDate,
    pHist.PostHistoryTypeId,
    ph.PostTypeName,
    ph.CloseReason
FROM UserStats us
JOIN RecentPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN PostHistoryData pHist ON rp.PostId = pHist.PostId
WHERE us.Rank <= 10
ORDER BY us.TotalBounty DESC, rp.CreationDate DESC
LIMIT 50;
