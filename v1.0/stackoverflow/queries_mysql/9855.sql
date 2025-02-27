
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        UpVoteCount,
        DownVoteCount,
        @PostRank := IF(@prevPostCount = PostCount, @PostRank, @rowNum) AS PostRank,
        @prevPostCount := PostCount,
        @rowNum := @rowNum + 1
    FROM 
        UserPostStats, (SELECT @rowNum := 1, @prevPostCount := NULL) AS vars
    ORDER BY 
        PostCount DESC
), CombinedRanked AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        UpVoteCount,
        DownVoteCount,
        PostRank,
        @UpVoteRank := IF(@prevUpVoteCount = UpVoteCount, @UpVoteRank, @rowNum) AS UpVoteRank,
        @prevUpVoteCount := UpVoteCount,
        (PostRank + UpVoteRank) AS CombinedRank
    FROM 
        RankedUsers, (SELECT @rowNum := 1, @prevUpVoteCount := NULL) AS vars
    ORDER BY 
        UpVoteCount DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    AnswerCount,
    QuestionCount,
    UpVoteCount,
    DownVoteCount,
    CombinedRank
FROM 
    CombinedRanked
WHERE 
    CombinedRank <= 10
ORDER BY 
    CombinedRank;
