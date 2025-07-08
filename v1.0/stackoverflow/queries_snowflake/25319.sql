
WITH TagStats AS (
    SELECT 
        TAG AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(ViewCount) AS AverageViewCount
    FROM (
        SELECT 
            unnest(split(substring(Tags, 2, char_length(Tags)-2), '><')) AS TAG,
            PostTypeId,
            ViewCount
        FROM 
            Posts
    ) AS split_tags
    GROUP BY 
        TAG
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
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
    WHERE 
        PostCount > 10 
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
        RANK() OVER (ORDER BY TotalPosts DESC, TotalVoteCount DESC) AS UserRank
    FROM 
        UserEngagement
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
    UserRanking ur ON ARRAY_CONTAINS(split(ur.DisplayName, ' '), tr.Tag) 
WHERE 
    tr.TagRank <= 5 
ORDER BY 
    tr.PostCount DESC, ur.UserRank;
