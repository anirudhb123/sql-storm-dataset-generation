WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpvoteCount,
        SUM(v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpvoteCount,
        DownvoteCount,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserMetrics
),
PopularQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
    HAVING 
        COUNT(c.Id) > 0
)
SELECT 
    tu.UserRank,
    tu.DisplayName AS TopUser,
    tu.Reputation,
    pq.ViewRank,
    pq.Title AS PopularQuestion,
    pq.ViewCount,
    pq.CommentCount,
    CASE 
        WHEN tu.QuestionCount > (SELECT AVG(QuestionCount) FROM UserMetrics) THEN 'Above Average'
        ELSE 'Below Average'
    END AS QuestionPerformance,
    COALESCE(STRING_AGG(b.Name, ', '), 'No Badges') AS Badges
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
LEFT JOIN 
    PopularQuestions pq ON tu.UserId IN (SELECT OwnerUserId FROM Posts WHERE PostTypeId = 1 AND ID IN (SELECT PostId FROM Comments))
WHERE 
    tu.UserRank <= 10 OR pq.ViewRank <= 5
GROUP BY 
    tu.UserRank, tu.DisplayName, tu.Reputation, pq.ViewRank, pq.Title, pq.ViewCount, pq.CommentCount
ORDER BY 
    tu.UserRank, pq.ViewRank;
