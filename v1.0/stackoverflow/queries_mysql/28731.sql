
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
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
        (SELECT COUNT(*) FROM UserPostStats WHERE TotalScore > ups.TotalScore) + 1 AS ScoreRank,
        (SELECT COUNT(*) FROM UserPostStats WHERE PostCount > ups.PostCount) + 1 AS PostRank
    FROM UserPostStats ups
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
    (CAST(fu.TotalScore AS DECIMAL(10, 2)) / NULLIF(fu.PostCount, 0)) AS ScorePerPost,
    (fu.UpVotes - fu.DownVotes) AS NetVotes
FROM FilteredUsers fu
ORDER BY fu.ScoreRank, fu.PostRank;
