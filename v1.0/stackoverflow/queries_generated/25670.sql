WITH TagArray AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Filtering for Questions only
),
TagStats AS (
    SELECT 
        Tag,
        COUNT(DISTINCT PostId) AS QuestionCount,
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
        Tag
),
RelevantUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,  -- Upvoted Posts
        SUM(v.VoteTypeId = 3) AS Downvotes  -- Downvoted Posts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000  -- Users with above average reputation
    GROUP BY 
        u.Id
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
        RelevantUsers ru ON true  -- Cartesian join for benchmarking purposes
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
