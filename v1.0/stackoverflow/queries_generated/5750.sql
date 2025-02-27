WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(u.Reputation) AS Reputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        QuestionCount, 
        AnswerCount, 
        Upvotes, 
        Downvotes, 
        BadgeCount, 
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStatistics
)
SELECT 
    UserId, 
    DisplayName, 
    PostCount, 
    QuestionCount, 
    AnswerCount, 
    Upvotes, 
    Downvotes, 
    BadgeCount, 
    Reputation
FROM TopUsers
WHERE Rank <= 10
ORDER BY Reputation DESC;
