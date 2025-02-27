WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(p.Score) AS TotalScore,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TagStats AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Posts p
    GROUP BY 
        TagName
),
PostHistoryAggregates AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.TotalAnswers,
    us.TotalQuestions,
    us.TotalScore,
    us.AvgReputation,
    ts.TagName,
    ts.PostCount,
    pha.EditCount,
    pha.LastEdited
FROM 
    UserStats us
JOIN 
    TagStats ts ON us.TotalPosts > 0
JOIN 
    PostHistoryAggregates pha ON us.TotalQuestions > 0
ORDER BY 
    us.TotalScore DESC, 
    us.TotalPosts DESC, 
    ts.PostCount DESC
LIMIT 100;
