WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS QuestionScore,
        SUM(CASE WHEN p.PostTypeId = 2 THEN p.Score ELSE 0 END) AS AnswerScore,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 0 
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        COUNT(DISTINCT ph.Id) AS RevisionCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypeNames,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.UserId
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS TagPostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        pa.PostCount,
        pa.TotalViews,
        pa.QuestionScore,
        pa.AnswerScore
    FROM 
        UserActivity ua
    JOIN 
        PostHistoryDetails phd ON ua.UserId = phd.UserId
    JOIN 
        PopularTags pt ON pt.TagPostCount > 5
    WHERE 
        ua.ActivityRank <= 50
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    COALESCE(tu.PostCount, 0) AS TotalPosts,
    COALESCE(tu.TotalViews, 0) AS Views,
    COALESCE(tu.QuestionScore, 0) AS TotalQuestionScore,
    COALESCE(tu.AnswerScore, 0) AS TotalAnswerScore,
    CASE 
        WHEN (tu.QuestionScore + tu.AnswerScore) > 100 THEN 'High Performer'
        WHEN (tu.QuestionScore + tu.AnswerScore) BETWEEN 50 AND 100 THEN 'Moderate Performer'
        ELSE 'Low Performer' 
    END AS PerformanceCategory,
    STRING_AGG(DISTINCT pht.Name, '; ') AS HistoryTypesInvolved
FROM 
    TopUsers tu
LEFT JOIN 
    PostHistoryDetails pht ON tu.UserId = pht.UserId
GROUP BY 
    tu.DisplayName, tu.Reputation, tu.PostCount, tu.TotalViews, tu.QuestionScore, tu.AnswerScore
ORDER BY 
    tu.Reputation DESC, tu.TotalPosts DESC
LIMIT 100;
