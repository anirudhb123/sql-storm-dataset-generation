WITH RecursivePostHierarchy AS (
    -- CTE to get post hierarchy for questions and answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
    WHERE p.PostTypeId = 2 -- Answers only
),
UserStatistics AS (
    -- CTE to gather user reputation and badge counts
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostViewCounts AS (
    -- CTE to get the view counts and related information for posts
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.ViewCount
)

SELECT 
    rph.PostId,
    rph.Title,
    rph.Level,
    us.DisplayName AS OwnerDisplayName,
    us.Reputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    pvc.ViewCount,
    pvc.Upvotes,
    pvc.Downvotes
FROM RecursivePostHierarchy rph
JOIN Users us ON rph.OwnerUserId = us.Id
JOIN PostViewCounts pvc ON rph.PostId = pvc.Id
WHERE rph.Level = 0 -- Only questions
AND us.Reputation > 1000 -- High reputation users
ORDER BY pvc.ViewCount DESC

OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; -- Limit to top 10 questions
