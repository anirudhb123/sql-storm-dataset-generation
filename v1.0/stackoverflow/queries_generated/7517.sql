WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
    WHERE 
        PostCount > 0
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        RANK() OVER (ORDER BY SUM(p.ViewCount) DESC) AS TagRank
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
),
TagStats AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        CASE 
            WHEN PostCount > 100 THEN 'Very Popular'
            WHEN PostCount > 50 THEN 'Popular'
            WHEN PostCount > 10 THEN 'Moderately Popular'
            ELSE 'Less Popular'
        END AS PopularityCategory
    FROM 
        PopularTags
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    ts.TagName,
    ts.PopularityCategory,
    ts.PostCount AS TagPostCount,
    ts.TotalViews AS TagTotalViews,
    tu.QuestionCount,
    tu.AnswerCount
FROM 
    TopUsers tu
JOIN 
    TagStats ts ON tu.UserId IN (
        SELECT 
            DISTINCT u.Id 
        FROM 
            Users u 
        JOIN 
            Posts p ON u.Id = p.OwnerUserId 
        JOIN 
            Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
        WHERE 
            p.PostTypeId = 1
    )
WHERE 
    tu.ReputationRank <= 10
ORDER BY 
    tu.Reputation DESC, 
    ts.TagPostCount DESC;
