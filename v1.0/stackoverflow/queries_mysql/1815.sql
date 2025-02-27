
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        MAX(p.CreationDate) AS LastActiveDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalUpVotes,
        TotalDownVotes,
        LastActiveDate,
        @rownum := @rownum + 1 AS UserRank
    FROM 
        UserStats, (SELECT @rownum := 0) r
    WHERE 
        LastActiveDate > NOW() - INTERVAL 1 YEAR
    ORDER BY 
        PostCount DESC, TotalUpVotes DESC
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalUpVotes,
        TotalDownVotes
    FROM 
        ActiveUsers
    WHERE 
        UserRank <= 10
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.Tags IS NOT NULL
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    COUNT(DISTINCT pt.Tag) AS DistinctTags,
    COALESCE(SUM(CASE WHEN ph.CreationDate IS NOT NULL THEN 1 ELSE 0 END), 0) AS EditsCount
FROM 
    TopUsers tu
LEFT JOIN 
    PostTags pt ON pt.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = tu.UserId
    )
LEFT JOIN 
    PostHistory ph ON ph.UserId = tu.UserId
WHERE 
    tu.TotalUpVotes > 100
GROUP BY 
    tu.UserId, tu.DisplayName, tu.PostCount, tu.QuestionCount, tu.AnswerCount, tu.TotalUpVotes, tu.TotalDownVotes
ORDER BY 
    tu.TotalUpVotes DESC;
