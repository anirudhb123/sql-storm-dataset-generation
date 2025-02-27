
WITH TagStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(ViewCount) AS AverageViewCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
         UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) 
            -CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n-1
    GROUP BY 
        Tag
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore,
        COALESCE(SUM(v.Count), 0) AS TotalVoteCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS Count
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        QuestionCount,
        AnswerCount,
        AverageViewCount,
        @rownum := @rownum + 1 AS TagRank
    FROM 
        TagStats, (SELECT @rownum := 0) r
    WHERE 
        PostCount > 10 
    ORDER BY 
        PostCount DESC
),
UserRanking AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalCommentScore,
        TotalVoteCount,
        @rank := IF(@prev = TotalPosts AND @prevVote = TotalVoteCount, @rank, @rank + 1) AS UserRank,
        @prev := TotalPosts,
        @prevVote := TotalVoteCount
    FROM 
        UserEngagement, (SELECT @rank := 0, @prev := NULL, @prevVote := NULL) r
    ORDER BY 
        TotalPosts DESC, TotalVoteCount DESC
)
SELECT 
    tr.Tag,
    tr.PostCount,
    tr.QuestionCount,
    tr.AnswerCount,
    tr.AverageViewCount,
    ur.UserId,
    ur.DisplayName,
    ur.TotalPosts,
    ur.Questions,
    ur.Answers,
    ur.TotalCommentScore,
    ur.TotalVoteCount,
    ur.UserRank
FROM 
    TopTags tr
JOIN 
    UserRanking ur ON FIND_IN_SET(tr.Tag, ur.DisplayName) > 0
WHERE 
    tr.TagRank <= 5 
ORDER BY 
    tr.PostCount DESC, ur.UserRank;
