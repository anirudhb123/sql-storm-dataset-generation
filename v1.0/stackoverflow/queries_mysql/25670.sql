
WITH TagArray AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT a.N + b.N * 10 + 1 AS n
         FROM 
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS a
         CROSS JOIN 
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS b) n
    WHERE 
        n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1
    AND 
        p.PostTypeId = 1  
),
TagStats AS (
    SELECT 
        t.Tag,
        COUNT(DISTINCT t.PostId) AS QuestionCount,
        SUM(
            CASE 
                WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
                ELSE 0 
            END
        ) AS AcceptedAnswerCount
    FROM 
        TagArray t
    JOIN 
        Posts p ON t.PostId = p.Id
    GROUP BY 
        t.Tag
),
RelevantUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes  
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000  
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
BenchmarkData AS (
    SELECT 
        ts.Tag,
        ts.QuestionCount,
        ts.AcceptedAnswerCount,
        ru.UserId,
        ru.DisplayName,
        ru.QuestionCount AS UserQuestionCount,
        ru.Upvotes,
        ru.Downvotes
    FROM 
        TagStats ts
    JOIN 
        RelevantUsers ru ON true  
)
SELECT 
    Tag,
    QuestionCount,
    AcceptedAnswerCount,
    COUNT(DISTINCT UserId) AS ActiveUserCount,
    AVG(UserQuestionCount) AS AvgUserQuestions,
    SUM(Upvotes) AS TotalUpvotes,
    SUM(Downvotes) AS TotalDownvotes
FROM 
    BenchmarkData
GROUP BY 
    Tag,
    QuestionCount,
    AcceptedAnswerCount
ORDER BY 
    QuestionCount DESC, AcceptedAnswerCount DESC;
