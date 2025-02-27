WITH RankedUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        Rank() OVER (ORDER BY Reputation DESC) AS UserRank,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(COALESCE(p.ViewCount, 0) + 1) AS AvgViewCount   -- Avoid division by zero
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        ru.Id,
        ru.DisplayName,
        ru.Reputation,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.AvgViewCount,
        COALESCE(NULLIF(ru.UserRank, 1), NULL) AS RankShift  -- Legacy NULL logic checking for top rank
    FROM RankedUsers AS ru
    JOIN PostStatistics AS ps ON ru.Id = ps.OwnerUserId
    WHERE ru.Reputation >= 100 AND ru.UserRank > 1   -- Filter out new users and top-ranked
),
RecentlyEditedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.LastEditDate,
        COUNT(DISTINCT ph.Id) AS EditHistory,
        ARRAY_AGG(DISTINCT ph.Comment) AS EditComments
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY p.Id
    HAVING COUNT(DISTINCT ph.Id) > 1  -- Consider only posts edited more than once
)
SELECT 
    au.DisplayName,
    au.Reputation,
    au.TotalPosts,
    au.TotalQuestions,
    au.TotalAnswers,
    au.AvgViewCount,
    r.concat( 'Active since ', TO_CHAR(MIN(u.CreationDate), 'Mon YY')) AS AccountAge,
    CASE
        WHEN au.RankShift IS NOT NULL THEN 'Former Top User'
        ELSE 'Active Contributor'
    END AS ContributorStatus,
    r.TagsInPostCount,
    p.Title AS RecentlyEditedPostTitle,
    COUNT(DISTINCT ph.Id) AS EditCount,
    STRING_AGG(DISTINCT ph.EditComments, '; ') AS Comments
FROM ActiveUsers au
LEFT JOIN RecentlyEditedPosts p ON au.Id = p.OwnerUserId
LEFT JOIN PostHistory ph ON p.PostId = ph.PostId
LEFT JOIN LATERAL (
    SELECT Count(array_length(string_to_array(p.Tags, '>'), 1)) AS TagsInPostCount
    FROM Posts p
    WHERE p.OwnerUserId = au.Id
) r ON TRUE
GROUP BY 
    au.DisplayName,
    au.Reputation,
    au.TotalPosts,
    au.TotalQuestions,
    au.TotalAnswers,
    au.AvgViewCount,
    p.Title  -- Grouping based on the post title to get a specific view on posts
ORDER BY au.Reputation DESC, EditCount DESC  -- Prioritize results by reputation and engagement
LIMIT 100 OFFSET 0;  -- Normal pagination
