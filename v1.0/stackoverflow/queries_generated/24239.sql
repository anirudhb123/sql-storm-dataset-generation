WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(v.BountyAmount) AS AvgBountyAmount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts, 
        QuestionCount, 
        AnswerCount, 
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM UserPostStats
    WHERE Reputation > 1000
),
ActivePostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(p.Tags, '><')) AS TagName,
        COUNT(c.Id) AS CommentCount,
        MAX(p.CreationDate) AS LastActivity
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.LastActivityDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id
),
FinalStats AS (
    SELECT 
        t.UserId,
        t.DisplayName,
        t.Reputation,
        t.TotalPosts,
        t.QuestionCount,
        t.AnswerCount,
        ap.TagName,
        ap.CommentCount,
        ap.LastActivity
    FROM TopUsers t
    LEFT JOIN ActivePostTags ap ON t.QuestionCount > 0
    ORDER BY t.UserRank, ap.LastActivity DESC
)
SELECT 
    fs.DisplayName,
    fs.Reputation,
    COALESCE(fs.TotalPosts, 0) AS TotalPosts,
    COALESCE(fs.QuestionCount, 0) AS QuestionCount,
    COALESCE(fs.AnswerCount, 0) AS AnswerCount,
    fs.TagName,
    fs.CommentCount,
    CASE 
        WHEN fs.LastActivity IS NULL THEN 'No Recent Activity'
        WHEN fs.LastActivity < NOW() - INTERVAL '7 days' THEN 'Inactive for a week'
        ELSE 'Active'
    END AS ActivityStatus
FROM FinalStats fs
WHERE fs.UserRank <= 10 
ORDER BY fs.Reputation DESC, fs.TotalPosts DESC;
