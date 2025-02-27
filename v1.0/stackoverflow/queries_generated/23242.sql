WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        COUNT(c.Id) AS TotalComments
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.OwnerUserId
),
ActivityStats AS (
    SELECT 
        ps.OwnerUserId,
        MAX(ps.CreationDate) AS LastActivityDate
    FROM Posts ps
    WHERE ps.CreationDate IS NOT NULL
    GROUP BY ps.OwnerUserId
),
FinalStats AS (
    SELECT
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.Views,
        us.UpVotes,
        us.DownVotes,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.TotalComments, 0) AS TotalComments,
        COALESCE(as.LastActivityDate, '1900-01-01'::timestamp) AS LastActivityDate 
    FROM UserStats us
    LEFT JOIN PostStats ps ON us.UserId = ps.OwnerUserId
    LEFT JOIN ActivityStats as ON us.UserId = as.OwnerUserId
),
RankedUsers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, Views DESC, UpVotes DESC) AS UserRank
    FROM FinalStats
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.Views,
    ru.UpVotes,
    ru.DownVotes,
    ru.TotalPosts,
    ru.TotalQuestions,
    ru.TotalAnswers,
    ru.TotalScore,
    ru.TotalComments,
    ru.LastActivityDate,
    CASE 
        WHEN ru.BadgeCount > 0 THEN 'Active Contributor'
        WHEN ru.TotalPosts = 0 AND ru.Reputation = 0 THEN 'Newbie'
        ELSE 'Regular User' 
    END AS UserCategory
FROM RankedUsers ru
WHERE ru.UserRank <= 100
    AND ru.LastActivityDate > (NOW() - INTERVAL '1 year')
ORDER BY ru.Reputation DESC, ru.Views DESC;

This SQL query performs multiple steps to fetch and analyze user activity on a StackOverflow-like platform. It creates Common Table Expressions (CTEs) to gather statistics about users, their posts, badges, and activity. It also classifies users based on their contributions and filters the results to show only the top 100 users with recent activity.
