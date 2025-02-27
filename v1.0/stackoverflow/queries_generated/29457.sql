WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation
    FROM 
        UserReputation ur
    WHERE 
        ur.Rank <= 10
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tu.UserId,
    tu.Reputation
FROM 
    TopTags tt
CROSS JOIN 
    TopUsers tu
WHERE 
    tt.Rank <= 5
ORDER BY 
    tt.PostCount DESC, tu.Reputation DESC;

