WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        UpVotes,
        DownVotes,
        BadgeCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM UserPostStats
),
FilteredUsers AS (
    SELECT
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        UpVotes,
        DownVotes,
        BadgeCount,
        ScoreRank,
        PostRank
    FROM RankedUsers
    WHERE ScoreRank <= 10 OR PostRank <= 10
)
SELECT 
    fu.DisplayName,
    fu.PostCount,
    fu.QuestionCount,
    fu.AnswerCount,
    fu.TotalScore,
    fu.UpVotes,
    fu.DownVotes,
    fu.BadgeCount,
    (fu.TotalScore::decimal / NULLIF(fu.PostCount, 0)) AS ScorePerPost,
    (fu.UpVotes - fu.DownVotes) AS NetVotes
FROM FilteredUsers fu
ORDER BY ScoreRank, PostRank;

This SQL query benchmarks string processing by retrieving user statistics, including the total number of posts, questions, answers, scores, votes, and badges. It ranks users based on their total score and post count, ultimately filtering to show the top users who excel either in score or post count. Each of these metrics is useful in evaluating user engagement and content contributions within the Stack Overflow platform.
