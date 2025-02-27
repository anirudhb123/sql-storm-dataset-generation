WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes
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
        QuestionCount,
        AnswerCount, 
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY PostCount DESC, UpVotes DESC) AS UserRank
    FROM 
        UserPostStats
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.UpVotes,
    tu.DownVotes,
    CASE 
        WHEN tu.UserRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributionLevel
FROM 
    TopUsers tu
WHERE 
    tu.PostCount > 0
ORDER BY 
    tu.UserRank;
