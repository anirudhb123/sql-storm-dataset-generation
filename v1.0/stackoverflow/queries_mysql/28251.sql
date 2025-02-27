
WITH TagFrequency AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionsAsked,
        SUM(COALESCE(p.AnswerCount, 0)) AS AnswersReceived,
        SUM(COALESCE(c.id, 0)) AS CommentsMade,
        SUM(COALESCE(v.Id, 0)) AS VotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId AND c.UserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId != u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionsAsked,
        ua.AnswersReceived,
        ua.CommentsMade,
        ua.VotesReceived,
        @rankQuestion := IF(@prevQuestion = ua.QuestionsAsked, @rankQuestion, @rankQuestion + 1) AS RankByQuestions,
        @prevQuestion := ua.QuestionsAsked,
        @rankAnswer := IF(@prevAnswer = ua.AnswersReceived, @rankAnswer, @rankAnswer + 1) AS RankByAnswers,
        @prevAnswer := ua.AnswersReceived,
        @rankComment := IF(@prevComment = ua.CommentsMade, @rankComment, @rankComment + 1) AS RankByComments,
        @prevComment := ua.CommentsMade
    FROM 
        UserActivity ua, (SELECT @rankQuestion := 0, @prevQuestion := NULL, @rankAnswer := 0, @prevAnswer := NULL, @rankComment := 0, @prevComment := NULL) r
    WHERE 
        ua.QuestionsAsked > 0
),
TagPerformance AS (
    SELECT
        tf.Tag,
        tf.TagCount,
        COUNT(DISTINCT p.Id) AS PostsAssociated,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(c.id, 0)) AS TotalComments
    FROM
        TagFrequency tf
    JOIN
        Posts p ON p.Tags LIKE CONCAT('%>', tf.Tag, '<%')
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY
        tf.Tag, tf.TagCount
)
SELECT 
    tu.DisplayName,
    tu.QuestionsAsked,
    tu.AnswersReceived,
    tu.CommentsMade,
    tu.VotesReceived,
    tp.Tag,
    tp.TagCount,
    tp.PostsAssociated,
    tp.TotalAnswers,
    tp.TotalComments
FROM 
    TopUsers tu
JOIN 
    TagPerformance tp ON tu.UserId = (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Tags LIKE CONCAT('%', tp.Tag, '%')
        LIMIT 1
    )
WHERE 
    tu.RankByQuestions <= 10 OR tu.RankByAnswers <= 10 OR tu.RankByComments <= 10
ORDER BY 
    tu.RankByQuestions, tu.RankByAnswers, tu.RankByComments;
