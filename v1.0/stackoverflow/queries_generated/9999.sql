WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes,
        COALESCE(SUM(c.Id), 0) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        Upvotes,
        Downvotes,
        CommentCount,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.Upvotes,
    tu.Downvotes,
    tu.CommentCount,
    ph.Name AS PostHistoryType,
    COUNT(ph.Id) AS HistoryCount
FROM 
    TopUsers tu
LEFT JOIN 
    PostHistory ph ON tu.UserId = ph.UserId
WHERE 
    tu.Rank <= 10
GROUP BY 
    tu.UserId, ph.Name
ORDER BY 
    tu.Reputation DESC, HistoryCount DESC;
