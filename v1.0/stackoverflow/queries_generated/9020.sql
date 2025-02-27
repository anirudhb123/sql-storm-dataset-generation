WITH UserStats AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) as PostCount,
        COUNT(DISTINCT c.Id) as CommentCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) as QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) as AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        PostCount,
        CommentCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC) as ReputationRank
    FROM 
        UserStats
    WHERE 
        PostCount > 0
),
PopularQuestions AS (
    SELECT 
        p.Id as QuestionId,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName as OwnerDisplayName,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) as PopularityRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
)
SELECT 
    t.DisplayName as TopUser,
    t.Reputation as UserReputation,
    tp.Title as PopularQuestion,
    tp.ViewCount as QuestionViewCount,
    tp.Score as QuestionScore,
    t.QuestionCount as UserQuestions,
    t.AnswerCount as UserAnswers
FROM 
    TopUsers t
JOIN 
    PopularQuestions tp ON t.QuestionCount > 0
WHERE 
    t.ReputationRank <= 10 AND tp.PopularityRank <= 10
ORDER BY 
    t.Reputation DESC, tp.Score DESC;
