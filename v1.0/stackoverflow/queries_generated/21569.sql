WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(pr.Score) AS TotalScore,
        AVG(pr.CreationDate) AS AvgPostDate,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT PostId, SUM(Score) AS Score FROM Posts GROUP BY PostId) pr ON p.Id = pr.PostId
    WHERE 
        u.Reputation > 1000 -- Only consider users with reputation greater than 1000
    GROUP BY 
        u.Id
),
RecentActivity AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ROW_NUMBER() OVER (PARTITION BY ua.UserId ORDER BY MAX(ph.CreationDate) DESC) AS Rank,
        MAX(ph.CreationDate) AS LastActiveDate,
        MAX(ph.PostId) AS LastPostId
    FROM 
        UserActivity ua
    LEFT JOIN 
        PostHistory ph ON ua.UserId = ph.UserId
    GROUP BY 
        ua.UserId, ua.DisplayName
),
AggregatedScores AS (
    SELECT 
        UserId,
        SUM(TotalScore) AS CumulativeScore
    FROM 
        UserActivity
    GROUP BY 
        UserId
)
SELECT 
    ra.UserId,
    ra.DisplayName,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ASCO.CumulativeScore,
    COALESCE(ra.LastActiveDate, 'Never Active') AS LastActiveDate,
    COALESCE(ua.AssociatedTags, 'No Tags') AS AssociatedTags,
    CASE 
        WHEN ua.TotalPosts > 50 THEN 'High Contributor'
        WHEN ua.TotalPosts BETWEEN 20 AND 50 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributionLevel,
    CASE 
        WHEN ra.LastPostId IS NULL THEN 'No Posts'
        ELSE 'Active Poster'
    END AS ActivityStatus
FROM 
    RecentActivity ra
LEFT JOIN 
    UserActivity ua ON ra.UserId = ua.UserId
LEFT JOIN 
    AggregatedScores ASCO ON ra.UserId = ASCO.UserId
WHERE 
    ra.Rank = 1 -- Get only the most recent activity for each user
ORDER BY 
    CumulativeScore DESC, TotalPosts DESC
LIMIT 100;
