WITH RECURSIVE PostHierarchy AS (
    SELECT p.Id, p.Title, p.CreationDate, p.ParentId
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
    
    UNION ALL
    
    SELECT p.Id, p.Title, p.CreationDate, p.ParentId
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.Id
),
UserContribution AS (
    SELECT u.Id AS UserId, 
           u.DisplayName,
           COUNT(DISTINCT p.Id) AS PostCount, 
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(v.VoteTypeId = 2) AS Upvotes,
           SUM(v.VoteTypeId = 3) AS Downvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           MAX(COALESCE(p.LastActivityDate, p.CreationDate)) AS LastActivity
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT uc.UserId,
           uc.DisplayName,
           uc.PostCount,
           uc.AnswerCount,
           uc.QuestionCount,
           ua.LastActivity,
           ROW_NUMBER() OVER (ORDER BY uc.PostCount DESC, uc.Upvotes DESC) AS Rank
    FROM UserContribution uc
    JOIN RecentActivity ua ON uc.UserId = ua.UserId
    WHERE uc.PostCount > 0 -- Considering only users with posts
)
SELECT tu.DisplayName, 
       tu.PostCount, 
       tu.AnswerCount, 
       tu.QuestionCount, 
       tu.LastActivity,
       (NOW() - tu.LastActivity) AS DaysSinceLastActivity,
       COALESCE(ph.Id, 0) AS HasChildPost,
       CASE WHEN tu.LastActivity < NOW() - INTERVAL '30 days' THEN 'Inactive' ELSE 'Active' END AS ActivityStatus
FROM TopUsers tu
LEFT JOIN PostHierarchy ph ON tu.UserId = ph.Id
WHERE tu.Rank <= 10 -- Top 10 users
ORDER BY tu.Rank;
