-- Performance Benchmarking SQL Query

WITH UsersStats AS (
    SELECT 
        Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN p.UpVotes IS NOT NULL THEN p.UpVotes ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN p.DownVotes IS NOT NULL THEN p.DownVotes ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),

TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        us.PostCount,
        us.QuestionsCount,
        us.AnswersCount,
        us.TotalUpVotes,
        us.TotalDownVotes,
        RANK() OVER (ORDER BY us.TotalUpVotes DESC) AS Ranking
    FROM 
        Users u
    JOIN 
        UsersStats us ON u.Id = us.UserId
)

SELECT 
    tu.Ranking,
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionsCount,
    tu.AnswersCount,
    tu.TotalUpVotes,
    tu.TotalDownVotes
FROM 
    TopUsers tu
WHERE 
    tu.Ranking <= 10
ORDER BY 
    tu.Ranking;
