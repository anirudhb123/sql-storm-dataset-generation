WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
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
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY UpVotes DESC) AS RankByUpVotes,
        ROW_NUMBER() OVER (ORDER BY AnswerCount DESC) AS RankByAnswers
    FROM 
        UserActivity
),
TopPostTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.AnswerCount,
    tu.QuestionCount,
    tu.UpVotes,
    tu.DownVotes,
    tpt.TagName,
    tpt.PostCount AS TagPostCount
FROM 
    TopUsers tu
JOIN 
    TopPostTags tpt ON tu.UserId IN (
        SELECT DISTINCT OwnerUserId 
        FROM Posts 
        WHERE Tags LIKE '%' + tpt.TagName + '%'
    )
WHERE 
    tu.RankByUpVotes <= 10 OR tu.RankByAnswers <= 10
ORDER BY 
    tu.UpVotes DESC, 
    tu.AnswerCount DESC;
