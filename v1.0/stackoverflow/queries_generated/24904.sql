WITH UserActivity AS (
    SELECT 
        u.Id as UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) as PostCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- Bounty starts
    WHERE 
        u.Reputation > 1000 
        AND u.CreationDate < CURRENT_DATE - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.Reputation, u.CreationDate, u.DisplayName, u.LastAccessDate
),
ActiveBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        b.UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        AVG(p.Score) AS AverageScore,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPosts,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedPosts
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.TotalBounty,
    ab.BadgeNames,
    ab.BadgeCount,
    ps.QuestionCount,
    ps.AnswerCount,
    ps.AverageScore,
    ps.ClosedPosts,
    ps.ReopenedPosts
FROM 
    UserActivity ua
LEFT JOIN 
    ActiveBadges ab ON ua.UserId = ab.UserId
LEFT JOIN 
    PostStats ps ON ua.UserId = ps.OwnerUserId
WHERE 
    (ab.BadgeCount IS NULL OR ab.BadgeCount > 5) 
    AND (ps.QuestionCount > 10 OR ps.AnswerCount IS NULL)
ORDER BY 
    ua.Reputation DESC, 
    ua.PostCount DESC
LIMIT 100;

-- This query generates a user activity report containing detailed statistics
-- about users with a reputation over 1000, looking at their post history,
-- badges awarded in the last year, and an aggregated view of their questions and answers.
-- It incorporates outer joins, CTEs, conditions on NULL logic, and multiple aggregations,
-- providing an intricate view of their interaction within the community.
