
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes, 
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
                SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes 
         GROUP BY PostId) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        TotalUpVotes, 
        TotalDownVotes,
        QuestionCount,
        AnswerCount,
        @row_number := IF(@prev_total_up_votes = TotalUpVotes, @row_number, @row_number + 1) AS UpVoteRank,
        @prev_total_up_votes := TotalUpVotes
    FROM 
        UserStats, (SELECT @row_number := 0, @prev_total_up_votes := NULL) AS vars
    ORDER BY TotalUpVotes DESC
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.QuestionCount,
    u.AnswerCount,
    GROUP_CONCAT(t.Title) AS TopQuestions
FROM 
    TopUsers u
LEFT JOIN 
    (SELECT 
         p.OwnerUserId, 
         p.Title, 
         p.ViewCount,
         @row_num := IF(@prev_user_id = p.OwnerUserId, @row_num + 1, 1) AS QuestionRank,
         @prev_user_id := p.OwnerUserId
     FROM 
         Posts p, (SELECT @row_num := 0, @prev_user_id := NULL) AS vars
     WHERE 
         p.PostTypeId = 1
     ORDER BY 
         p.OwnerUserId, p.ViewCount DESC) t ON u.UserId = t.OwnerUserId AND t.QuestionRank <= 5
WHERE 
    u.UpVoteRank <= 10
GROUP BY 
    u.DisplayName, 
    u.Reputation, 
    u.PostCount, 
    u.TotalUpVotes, 
    u.TotalDownVotes,
    u.QuestionCount,
    u.AnswerCount
ORDER BY 
    u.TotalUpVotes DESC;
