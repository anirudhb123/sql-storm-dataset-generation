WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserActivity
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    INNER JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
UserTagInteraction AS (
    SELECT 
        u.Id AS UserId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS InteractionCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        u.Id, t.TagName
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.UpVotes,
    tu.DownVotes,
    STRING_AGG(DISTINCT ut.TagName, ', ') AS AcquiredTags,
    SUM(ut.InteractionCount) AS TagInteractions
FROM 
    TopUsers tu
LEFT JOIN 
    UserTagInteraction ut ON tu.UserId = ut.UserId
GROUP BY 
    tu.UserId, tu.DisplayName, tu.TotalPosts, tu.QuestionCount, tu.AnswerCount, tu.UpVotes, tu.DownVotes
HAVING 
    COUNT(DISTINCT ut.TagName) > 3
ORDER BY 
    tu.PostRank
LIMIT 10;
