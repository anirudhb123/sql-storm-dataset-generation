WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(p.Score) AS TotalScore,
        ROW_NUMBER() OVER (ORDER BY SUM(p.Score) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
), 
RecentBadges AS (
    SELECT 
        b.UserId, 
        b.Name AS BadgeName, 
        b.Class,
        ROW_NUMBER() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM Badges b
    WHERE b.Date > NOW() - INTERVAL '1 year' 
),
PostHistorySummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditedTimestamp,
        STRING_AGG(DISTINCT ph.Comment, ', ') AS EditComments
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId 
    GROUP BY p.Id
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.AcceptedAnswers,
    ups.TotalScore,
    rb.BadgeName,
    rb.Class,
    phs.EditCount,
    phs.LastEditedTimestamp,
    phs.EditComments
FROM UserPostStats ups
LEFT JOIN RecentBadges rb ON ups.UserId = rb.UserId AND rb.BadgeRank = 1
LEFT JOIN PostHistorySummary phs ON EXISTS (
    SELECT 1
    FROM Posts p
    WHERE p.OwnerUserId = ups.UserId AND p.Id = phs.PostId
)
WHERE ups.TotalPosts > 0 
ORDER BY ups.Rank
LIMIT 100;
