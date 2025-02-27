WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswers,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        AcceptedAnswers,
        Rank
    FROM 
        UserPostStats
    WHERE 
        Rank <= 10
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.UpVotes,
    tu.DownVotes,
    tu.AcceptedAnswers,
    STUFF((
        SELECT 
            ', ' + CAST(tags.TagName AS VARCHAR(35))
        FROM 
            Tags tags
        JOIN 
            STRING_SPLIT((SELECT TOP 1 p.Tags FROM Posts p WHERE p.OwnerUserId = tu.UserId ORDER BY p.CreationDate DESC), ',') t ON t.value = tags.TagName
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS RecentTags
FROM 
    TopUsers tu
ORDER BY 
    tu.PostCount DESC;
