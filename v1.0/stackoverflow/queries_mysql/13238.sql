
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        QuestionCount, 
        AnswerCount, 
        UpVoteCount, 
        DownVoteCount,
        @rankByPosts := IF(@prevPostCount = PostCount, @rankByPosts, @rowNumber) AS RankByPosts,
        @prevPostCount := PostCount,
        @rowNumber := @rowNumber + 1
    FROM 
        UserPostStats, (SELECT @rowNumber := 0, @prevPostCount := NULL, @rankByPosts := 0) AS vars
    ORDER BY 
        PostCount DESC
),
FinalUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        QuestionCount, 
        AnswerCount, 
        UpVoteCount, 
        DownVoteCount,
        RankByPosts,
        @rankByUpVotes := IF(@prevUpVoteCount = UpVoteCount, @rankByUpVotes, @rowNumber) AS RankByUpVotes,
        @prevUpVoteCount := UpVoteCount,
        @rowNumber := @rowNumber + 1
    FROM 
        TopUsers, (SELECT @rowNumber := 0, @prevUpVoteCount := NULL, @rankByUpVotes := 0) AS vars
    ORDER BY 
        UpVoteCount DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    UpVoteCount,
    DownVoteCount,
    RankByPosts,
    RankByUpVotes
FROM 
    FinalUsers
WHERE 
    RankByPosts <= 10 OR RankByUpVotes <= 10
ORDER BY 
    RankByPosts, RankByUpVotes;
