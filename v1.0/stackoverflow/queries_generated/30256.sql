WITH RECURSIVE TagHierarchy AS (
    SELECT Id, TagName, Count, 1 AS Level
    FROM Tags
    WHERE Count > 100  -- Only consider popular tags

    UNION ALL

    SELECT t.Id, t.TagName, t.Count, th.Level + 1
    FROM Tags t
    JOIN TagHierarchy th ON t.ExcerptPostId = th.Id
    WHERE th.Level < 3  -- Limit the hierarchy to 3 levels
),

UserWithBadges AS (
    SELECT u.Id AS UserId, u.DisplayName, 
           COUNT(b.Id) AS BadgeCount, 
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),

PostStatistics AS (
    SELECT p.Id AS PostId, p.Title, 
           COALESCE(p.AnswerCount, 0) AS TotalAnswers, 
           COALESCE(p.ViewCount, 0) AS TotalViews,
           AVG(v.CreationDate) AS AvgVoteDate,  -- Average vote timing
           MAX(CASE WHEN v.VoteTypeId = 2 THEN v.CreationDate END) AS LastUpvoteDate
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)

SELECT 
    uwb.UserId,
    uwb.DisplayName,
    uwb.BadgeCount,
    uwb.GoldBadges,
    uwb.SilverBadges,
    uwb.BronzeBadges,
    ph.PostId,
    ph.Title,
    ph.TotalAnswers,
    ph.TotalViews,
    th.TagName,
    th.Level,
    ph.AvgVoteDate,
    ph.LastUpvoteDate
FROM UserWithBadges uwb
JOIN PostStatistics ph ON uwb.UserId = ph.PostId  -- Assumes posts authored by the user
JOIN TagHierarchy th ON ph.PostId = th.Id  -- Join with popular tags
WHERE uwb.BadgeCount > 0  -- Only users with badges
  AND ph.TotalAnswers > 5  -- Only consider posts with significant answers
  AND ph.AvgVoteDate IS NOT NULL  -- Ensure there's voting activity
ORDER BY uwb.BadgeCount DESC, ph.TotalViews DESC;  -- Order by badge count and view count
