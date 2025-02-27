WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(c.Score) AS TotalCommentScore,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalCommentScore,
        TotalBounty,
        RANK() OVER (ORDER BY PostCount DESC, Reputation DESC) AS rn
    FROM UserActivity
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalCommentScore,
    TotalBounty
FROM TopUsers
WHERE rn <= 10;

SELECT 
    pt.Name AS PostType,
    COUNT(*) AS NumberOfPosts,
    SUM(p.ViewCount) AS TotalViews
FROM Posts p
JOIN PostTypes pt ON p.PostTypeId = pt.Id
WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY pt.Name
ORDER BY TotalViews DESC;

SELECT 
    bt.Name AS BadgeType,
    COUNT(b.UserId) AS NumberOfUsers
FROM Badges b
JOIN PostHistoryTypes ht ON b.Name = ht.Name
GROUP BY bt.Name
ORDER BY NumberOfUsers DESC;

SELECT 
    T.TagName,
    COUNT(p.Id) AS PostsWithTag,
    AVG(vote_count) AS AvgVotes
FROM Tags T
JOIN Posts p ON p.Tags LIKE CONCAT('%<', T.TagName, '>%')
JOIN (SELECT PostId, COUNT(*) AS vote_count FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
GROUP BY T.TagName
HAVING COUNT(p.Id) > 5
ORDER BY AvgVotes DESC;
