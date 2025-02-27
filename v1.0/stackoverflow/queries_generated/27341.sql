WITH TagCounts AS (
    SELECT
        tag.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPostCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedPostCount
    FROM Tags tag
    JOIN Posts p ON p.Tags LIKE CONCAT('%<', tag.TagName, '>%')  -- Join Posts where Tags contain this tag
    LEFT JOIN PostHistory ph ON ph.PostId = p.Id  -- Left join to gather post history details
    GROUP BY tag.TagName
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotesReceived
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.UpVotesReceived,
        RANK() OVER (ORDER BY ua.UpVotesReceived DESC) AS UserRank
    FROM UserActivity ua
    WHERE ua.QuestionCount > 0
    ORDER BY ua.UpVotesReceived DESC
    LIMIT 10
)

SELECT 
    tc.TagName,
    tc.PostCount,
    tc.ClosedPostCount,
    tc.ReopenedPostCount,
    tu.DisplayName AS TopUser,
    tu.UpVotesReceived
FROM TagCounts tc
LEFT JOIN TopUsers tu ON tu.UserId = (
    SELECT UserId 
    FROM TopUsers 
    WHERE UserRank = 1  -- Get the top user for this tag if possible
    LIMIT 1
)
ORDER BY tc.PostCount DESC
LIMIT 10;
