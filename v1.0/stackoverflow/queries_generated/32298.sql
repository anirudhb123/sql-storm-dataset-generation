WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        1 AS Level,
        p.OwnerUserId,
        p.Title,
        p.CreationDate
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Start with Questions

    UNION ALL

    SELECT 
        p2.Id AS PostId,
        rph.Level + 1 AS Level,
        p2.OwnerUserId,
        p2.Title,
        p2.CreationDate
    FROM Posts p2
    INNER JOIN RecursivePostHierarchy rph ON p2.ParentId = rph.PostId
),

UserReputationImpact AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS AnswerCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2 -- Answers
    GROUP BY u.Id, u.Reputation
),

PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        MAX(ph.CreationDate) AS LastActivity
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title
)

SELECT 
    rph.PostId,
    rph.Level,
    rph.Title AS QuestionTitle,
    COALESCE(ur.AnswerCount, 0) AS Answers,
    COALESCE(ur.TotalViews, 0) AS TotalViews,
    COALESCE(ur.TotalScore, 0) AS TotalScore,
    ps.CommentCount,
    ps.TotalBounty,
    ps.LastActivity
FROM RecursivePostHierarchy rph
LEFT JOIN UserReputationImpact ur ON rph.OwnerUserId = ur.UserId
LEFT JOIN PostSummary ps ON rph.PostId = ps.PostId
WHERE rph.CreationDate >= NOW() - INTERVAL '30 days' -- Only consider posts from the last 30 days
ORDER BY rph.Level, rph.Title;

WITH UserActivity AS (
    SELECT 
        u.DisplayName,
        u.CreationDate,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS TotalPosts,
        (SELECT COUNT(*) FROM Comments c WHERE c.UserId = u.Id) AS TotalComments,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS TotalBadges
    FROM Users u
    WHERE u.Reputation > 1000
)

SELECT 
    ua.DisplayName,
    ua.CreationDate,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBadges,
    COALESCE(SUM(CASE 
        WHEN p.ViewCount IS NULL THEN 0 
        ELSE p.ViewCount 
    END), 0) AS TotalViews
FROM UserActivity ua
LEFT JOIN Posts p ON p.OwnerUserId IN (SELECT UserId FROM UserActivity) 
GROUP BY ua.DisplayName, ua.CreationDate, ua.TotalPosts, ua.TotalComments, ua.TotalBadges
ORDER BY ua.TotalPosts DESC, ua.TotalComments DESC;
