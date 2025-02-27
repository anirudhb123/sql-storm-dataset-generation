
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
PopularUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        BadgeCount,
        CommentCount,
        @VoteRank := IF(@prevUpVotes = UpVotes, @VoteRank, @rowNum) AS VoteRank,
        @QuestionRank := IF(@prevQuestionCount = QuestionCount, @QuestionRank, @rowNum) AS QuestionRank,
        @prevUpVotes := UpVotes,
        @prevQuestionCount := QuestionCount,
        @rowNum := @rowNum + 1
    FROM UserActivity, (SELECT @rowNum := 0, @VoteRank := 0, @prevUpVotes := NULL, @QuestionRank := 0, @prevQuestionCount := NULL) AS vars
    ORDER BY UpVotes DESC
)
SELECT 
    pu.DisplayName,
    pu.QuestionCount,
    pu.AnswerCount,
    pu.UpVotes,
    pu.DownVotes,
    pu.BadgeCount,
    pu.CommentCount,
    LEAST(pu.VoteRank, pu.QuestionRank) AS OverallRank
FROM PopularUsers pu
WHERE pu.QuestionCount > 0 OR pu.AnswerCount > 0
ORDER BY OverallRank, pu.UpVotes DESC
LIMIT 10;
