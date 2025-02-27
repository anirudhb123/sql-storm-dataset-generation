
WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        @row_num := @row_num + 1 AS TagRank
    FROM 
        TagCounts, (SELECT @row_num := 0) AS r
    WHERE 
        PostCount > 0
    ORDER BY 
        PostCount DESC
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCreated,
        UpvotesReceived,
        DownvotesReceived,
        @user_row_num := @user_row_num + 1 AS UserRank
    FROM 
        UserEngagement, (SELECT @user_row_num := 0) AS r
    WHERE 
        PostsCreated > 0
    ORDER BY 
        PostsCreated DESC
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    tu.DisplayName AS TopUser,
    tu.PostsCreated,
    tu.UpvotesReceived,
    tu.DownvotesReceived
FROM 
    TopTags tt
JOIN 
    TopUsers tu ON tt.TagRank = tu.UserRank
WHERE 
    tt.TagRank <= 10
ORDER BY 
    tt.PostCount DESC, tu.PostsCreated DESC;
