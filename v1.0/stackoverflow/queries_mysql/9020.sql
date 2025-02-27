
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.UpVotes, u.DownVotes
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
        @rank := IF(@prev_reputation = Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_reputation := Reputation
    FROM 
        UserStats, (SELECT @rank := 0, @prev_reputation := NULL) AS vars
    WHERE 
        PostCount > 0
    ORDER BY 
        Reputation DESC
),
PopularQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        @pop_rank := IF(@prev_score = p.Score AND @prev_view_count = p.ViewCount, @pop_rank, @pop_rank + 1) AS PopularityRank,
        @prev_score := p.Score,
        @prev_view_count := p.ViewCount
    FROM 
        Posts p, Users u, (SELECT @pop_rank := 0, @prev_score := NULL, @prev_view_count := NULL) AS vars
    WHERE 
        p.OwnerUserId = u.Id AND p.PostTypeId = 1
    ORDER BY 
        p.Score DESC, p.ViewCount DESC
)
SELECT 
    t.DisplayName AS TopUser,
    t.Reputation AS UserReputation,
    tp.Title AS PopularQuestion,
    tp.ViewCount AS QuestionViewCount,
    tp.Score AS QuestionScore,
    t.QuestionCount AS UserQuestions,
    t.AnswerCount AS UserAnswers
FROM 
    TopUsers t
JOIN 
    PopularQuestions tp ON t.QuestionCount > 0
WHERE 
    t.ReputationRank <= 10 AND tp.PopularityRank <= 10
ORDER BY 
    t.Reputation DESC, tp.Score DESC;
