WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(COALESCE(b.Class, 0)) AS AvgBadgeClass
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Questions
    LEFT JOIN Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2  -- Answers
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9)  -- Bounties
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId AS CloserUserId,
        ph.CreationDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.UserId, ph.CreationDate
),
ActiveUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        TotalBounty,
        AvgBadgeClass,
        ROW_NUMBER() OVER (PARTITION BY UserId ORDER BY QuestionCount DESC, AnswerCount DESC) AS RN
    FROM UserActivity
    WHERE QuestionCount > 5 AND AnswerCount > 5
),
UserCloseStats AS (
    SELECT
        a.UserId,
        a.DisplayName,
        COUNT(DISTINCT cp.PostId) AS ClosedPostCount,
        COUNT(DISTINCT cp.CloserUserId) AS UniqueClosers
    FROM ClosedPosts cp
    JOIN ActiveUsers a ON cp.CloserUserId = a.UserId
    GROUP BY a.UserId, a.DisplayName
)
SELECT 
    a.UserId,
    a.DisplayName,
    a.QuestionCount,
    a.AnswerCount,
    a.TotalBounty,
    a.AvgBadgeClass,
    COALESCE(u.ClosedPostCount, 0) AS ClosedPostCount,
    COALESCE(u.UniqueClosers, 0) AS UniqueClosers,
    CASE 
        WHEN a.AnswerCount > a.QuestionCount THEN 'More Active in Answers'
        WHEN a.QuestionCount > a.AnswerCount THEN 'More Active in Questions'
        ELSE 'Balanced Activity'
    END AS ActivityType
FROM ActiveUsers a
LEFT JOIN UserCloseStats u ON a.UserId = u.UserId
ORDER BY a.TotalBounty DESC, a.QuestionCount DESC;

This SQL query captures various insights about users with significant activity on a Stack Overflow-like platform, utilizing CTEs to structure the data progressively. It calculates user statistics such as the number of questions and answers, total bounties received, and average badge class, alongside statistics about posts they've closed. It further categorizes users based on their activity type in questions and answers and sorts the results by bounties and question counts. Edge cases such as users with no closed posts or varying counts across questions and answers are addressed through COALESCE and partitioning techniques.
