WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryStats AS (
    SELECT
        ph.UserId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosedPosts,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeletedPosts
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
),
CombinedStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.Questions,
        us.Answers,
        us.AcceptedAnswers,
        COALESCE(phs.ClosedPosts, 0) AS ClosedPosts,
        COALESCE(phs.DeletedPosts, 0) AS DeletedPosts,
        CASE 
            WHEN us.Reputation >= 1000 THEN 'Expert'
            WHEN us.Reputation >= 100 THEN 'Experienced'
            ELSE 'Novice' 
        END AS UserLevel
    FROM 
        UserStats us
    LEFT JOIN 
        PostHistoryStats phs ON us.UserId = phs.UserId
)
SELECT 
    c.DisplayName,
    c.Reputation,
    c.TotalPosts,
    c.Questions,
    c.Answers,
    c.AcceptedAnswers,
    c.ClosedPosts,
    c.DeletedPosts,
    c.UserLevel,
    ROW_NUMBER() OVER (ORDER BY c.Reputation DESC) AS Rank
FROM 
    CombinedStats c
WHERE 
    c.TotalPosts > 0
ORDER BY 
    c.Reputation DESC
LIMIT 10;

-- Extension Query for Optional Statistics
UNION ALL
SELECT 
    'Total' AS DisplayName,
    SUM(Reputation) AS Reputation,
    SUM(TotalPosts) AS TotalPosts,
    SUM(Questions) AS TotalQuestions,
    SUM(Answers) AS TotalAnswers,
    SUM(AcceptedAnswers) AS TotalAcceptedAnswers,
    SUM(ClosedPosts) AS TotalClosedPosts,
    SUM(DeletedPosts) AS TotalDeletedPosts,
    NULL AS UserLevel,
    NULL AS Rank
FROM 
    CombinedStats;

-- Final Notes: 
-- Adjust the ORDER BY and filtering strategies based on specific needs.
