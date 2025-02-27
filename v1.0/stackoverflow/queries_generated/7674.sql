WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        COALESCE(SUM(SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = p.Id AND v2.VoteTypeId IN (1, 2, 3)), 0) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
    WHERE 
        PostCount > 0
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    pt.TagName,
    pt.TagCount
FROM 
    TopUsers tu
JOIN 
    PopularTags pt ON pt.TagCount > 0
WHERE 
    tu.ReputationRank <= 10
ORDER BY 
    tu.Reputation DESC, 
    pt.TagCount DESC;
