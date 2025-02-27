WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS TotalQuestionScore
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
        AnswerCount, 
        TotalQuestionScore,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS UseCount
    FROM 
        Tags t
    INNER JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    INNER JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        UseCount,
        ROW_NUMBER() OVER (ORDER BY UseCount DESC) AS Rank
    FROM 
        PopularTags
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.AnswerCount,
    pt.TagName,
    pt.UseCount
FROM 
    TopUsers tu
JOIN 
    TopTags pt ON pt.Rank <= 10
WHERE 
    tu.Rank <= 20
ORDER BY 
    tu.Reputation DESC, pt.UseCount DESC;
