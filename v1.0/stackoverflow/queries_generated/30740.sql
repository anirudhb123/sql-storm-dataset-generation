WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.ViewCount) AS AvgViewCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- Bounty Start and Close
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        PositivePostCount,
        NegativePostCount,
        QuestionCount,
        AnswerCount,
        AvgViewCount,
        TotalBounty,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM UserPostStats
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPostCount
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
FinalStats AS (
    SELECT 
        t.DisplayName,
        t.PostCount,
        t.PositivePostCount,
        t.NegativePostCount,
        t.QuestionCount,
        t.AnswerCount,
        t.AvgViewCount,
        t.TotalBounty,
        a.CommentCount,
        a.ClosedPostCount
    FROM TopUsers t
    LEFT JOIN UserActivity a ON t.UserId = a.UserId
)

SELECT 
    f.DisplayName,
    f.PostCount,
    f.PositivePostCount,
    f.NegativePostCount,
    f.QuestionCount,
    f.AnswerCount,
    f.AvgViewCount,
    f.TotalBounty,
    COALESCE(a.CommentCount, 0) AS CommentCount,
    COALESCE(a.ClosedPostCount, 0) AS ClosedPostCount,
    CASE 
        WHEN f.PostCount > 10 THEN 'Active User'
        WHEN f.PostCount BETWEEN 5 AND 10 THEN 'Moderate User'
        ELSE 'Inactive User'
    END AS UserType
FROM FinalStats f
WHERE f.PostCount > 0  -- Only include active users with at least one post
ORDER BY f.PostCount DESC;
