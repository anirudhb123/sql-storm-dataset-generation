
WITH UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpvoteCount,
        DownvoteCount,
        BadgeCount,
        LastPostDate,
        @PostRank := IF(@prevPostCount = PostCount, @PostRank, @rank) AS PostRank,
        @prevPostCount := PostCount,
        @rank := @rank + 1
    FROM UserActivity, (SELECT @rank := 1, @prevPostCount := NULL) AS init
    ORDER BY PostCount DESC
),
TempUpvoteRank AS (
    SELECT 
        *,
        @UpvoteRank := IF(@prevUpvoteCount = UpvoteCount, @UpvoteRank, @rank) AS UpvoteRank,
        @prevUpvoteCount := UpvoteCount,
        @rank := @rank + 1
    FROM TopUsers, (SELECT @rank := 1, @prevUpvoteCount := NULL) AS init
    ORDER BY UpvoteCount DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    UpvoteCount,
    DownvoteCount,
    BadgeCount,
    LastPostDate,
    PostRank,
    UpvoteRank
FROM TempUpvoteRank
WHERE PostRank <= 10 OR UpvoteRank <= 10
ORDER BY PostRank, UpvoteRank;
