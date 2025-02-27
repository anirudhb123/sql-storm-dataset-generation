WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
TopPostUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        AvgViews,
        ReputationRank
    FROM 
        UserPostStats
    WHERE 
        ReputationRank <= 10
), 
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS HistoryCount,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - ph.CreationDate))) AS AvgAgeInDays
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) 
    GROUP BY 
        ph.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(stats.PostCount, 0) AS TotalPosts,
    COALESCE(stats.QuestionCount, 0) AS TotalQuestions,
    COALESCE(stats.AnswerCount, 0) AS TotalAnswers,
    COALESCE(phs.HistoryCount, 0) AS HistoryChanges,
    CASE 
        WHEN COALESCE(phs.AvgAgeInDays, 0) > 30 THEN 'Inactive'
        WHEN COALESCE(phs.AvgAgeInDays, 0) <= 30 AND COALESCE(stats.PostCount, 0) > 50 THEN 'Active Contributor'
        ELSE 'Moderate Activity'
    END AS ActivityStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    Users u
LEFT JOIN 
    TopPostUsers stats ON u.Id = stats.UserId
LEFT JOIN 
    PostHistoryStats phs ON u.Id = phs.UserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    unnest(string_to_array(p.Tags, ',')) AS tag ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = TRIM(tag)
GROUP BY 
    u.DisplayName, u.Reputation, phs.HistoryCount, phs.AvgAgeInDays
ORDER BY 
    u.Reputation DESC, TotalPosts DESC
FETCH FIRST 50 ROWS ONLY;
