WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS QuestionsAnswered,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 -- BountyClose votes
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views, u.UpVotes, u.DownVotes
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        UpVotes,
        DownVotes,
        TotalPosts,
        TotalComments,
        QuestionsAnswered,
        TotalAnswers,
        AverageBounty,
        RANK() OVER (ORDER BY TotalPosts DESC, Reputation DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    tu.Views,
    tu.UpVotes,
    tu.DownVotes,
    tu.TotalPosts,
    tu.TotalComments,
    tu.QuestionsAnswered,
    tu.TotalAnswers,
    tu.AverageBounty,
    JSON_AGG(DISTINCT json_build_object('PostId', p.Id, 'Title', p.Title, 'CreationDate', p.CreationDate)) AS PostsDetails
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
WHERE 
    tu.Rank <= 10
GROUP BY 
    tu.Rank, tu.DisplayName, tu.Reputation, tu.Views, tu.UpVotes, tu.DownVotes, 
    tu.TotalPosts, tu.TotalComments, tu.QuestionsAnswered, tu.TotalAnswers, tu.AverageBounty
ORDER BY 
    tu.Rank;
