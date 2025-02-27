WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount,
        SUM(CASE WHEN pt.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(SUBSTRING(pt.Title, 1, 10)) AS SampleTitleLength
    FROM 
        Tags t
    JOIN 
        Posts pt ON t.Id = ANY(string_to_array(pt.Tags, '><')::int[])
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 10
),

RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),

PostsWithRecentHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        up.Reputation AS UserReputation,
        COUNT(rh.PostId) AS RecentHistoryCount
    FROM 
        Posts p
    JOIN 
        Users up ON p.OwnerUserId = up.Id
    LEFT JOIN 
        RecentPostHistory rh ON p.Id = rh.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, up.Reputation
)

SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.TotalPosts,
    ru.TotalAnswers,
    ru.AcceptedAnswers,
    pt.TagName,
    pt.PostCount AS PopularPostCount,
    pt.QuestionCount AS PopularQuestionCount,
    pwr.PostId,
    pwr.Title AS RecentPostTitle,
    pwr.UserReputation,
    pwr.RecentHistoryCount
FROM 
    RankedUsers ru
JOIN 
    PopularTags pt ON ru.TotalPosts > 5
JOIN 
    PostsWithRecentHistory pwr ON pt.PostCount > 10
ORDER BY 
    ru.UserRank, pt.PostCount DESC, pwr.RecentHistoryCount DESC;
