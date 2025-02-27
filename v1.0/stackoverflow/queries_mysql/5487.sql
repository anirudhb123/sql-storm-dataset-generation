
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
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
        PostCount,
        AnswerCount,
        QuestionCount,
        UpVotes,
        DownVotes,
        @rankByUpVotes := IF(@prevUpVotes = UpVotes, @rankByUpVotes, @rowNumber) AS RankByUpVotes,
        @prevUpVotes := UpVotes,
        @rowNumber := @rowNumber + 1
    FROM 
        UserActivity, (SELECT @rowNumber := 0, @prevUpVotes := NULL) AS vars
    ORDER BY 
        UpVotes DESC
),
RankedByAnswers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        UpVotes,
        DownVotes,
        @rankByAnswers := IF(@prevAnswers = AnswerCount, @rankByAnswers, @rowNumberAnswers) AS RankByAnswers,
        @prevAnswers := AnswerCount,
        @rowNumberAnswers := @rowNumberAnswers + 1
    FROM 
        TopUsers, (SELECT @rowNumberAnswers := 0, @prevAnswers := NULL) AS vars
    ORDER BY 
        AnswerCount DESC
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
    RankedByAnswers tu
JOIN 
    (SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10) tpt ON tu.UserId IN (
        SELECT DISTINCT OwnerUserId 
        FROM Posts 
        WHERE Tags LIKE CONCAT('%', tpt.TagName, '%')
    )
WHERE 
    tu.RankByUpVotes <= 10 OR tu.RankByAnswers <= 10
ORDER BY 
    tu.UpVotes DESC, 
    tu.AnswerCount DESC;
