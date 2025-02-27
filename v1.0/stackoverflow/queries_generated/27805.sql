WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        STRING_AGG(t.TagName, ', ') AS CombinedTags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')::int[]))
    WHERE 
        p.PostTypeId IN (1, 2)  -- Only questions and answers
    GROUP BY 
        p.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC, QuestionCount DESC
    LIMIT 10
)
SELECT 
    ru.PostId,
    ru.Title,
    ru.Body,
    ru.CombinedTags,
    ru.OwnerDisplayName,
    ru.CreationDate,
    ru.Score,
    tu.DisplayName AS TopUserName,
    tu.QuestionCount,
    tu.TotalScore,
    tu.AvgReputation
FROM 
    RankedPosts ru
JOIN 
    TopUsers tu ON ru.OwnerDisplayName = tu.DisplayName
WHERE 
    ru.Rank <= 5  -- Get top 5 recent posts of each user
ORDER BY 
    tu.TotalScore DESC, ru.CreationDate DESC;
