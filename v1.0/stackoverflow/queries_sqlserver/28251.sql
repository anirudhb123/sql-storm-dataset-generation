
WITH TagFrequency AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS t
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionsAsked,
        SUM(ISNULL(p.AnswerCount, 0)) AS AnswersReceived,
        SUM(ISNULL(c.Id, 0)) AS CommentsMade,
        SUM(ISNULL(v.Id, 0)) AS VotesReceived
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
        RANK() OVER (ORDER BY ua.QuestionsAsked DESC) AS RankByQuestions,
        RANK() OVER (ORDER BY ua.AnswersReceived DESC) AS RankByAnswers,
        RANK() OVER (ORDER BY ua.CommentsMade DESC) AS RankByComments
    FROM 
        UserActivity ua
    WHERE 
        ua.QuestionsAsked > 0
),
TagPerformance AS (
    SELECT
        tf.Tag,
        tf.TagCount,
        COUNT(DISTINCT p.Id) AS PostsAssociated,
        SUM(ISNULL(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(ISNULL(c.Id, 0)) AS TotalComments
    FROM
        TagFrequency tf
    JOIN
        Posts p ON p.Tags LIKE '%' + tf.Tag + '%'
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
        SELECT TOP 1 OwnerUserId 
        FROM Posts 
        WHERE Tags LIKE '%' + tp.Tag + '%'
    )
WHERE 
    tu.RankByQuestions <= 10 OR tu.RankByAnswers <= 10 OR tu.RankByComments <= 10
ORDER BY 
    tu.RankByQuestions, tu.RankByAnswers, tu.RankByComments;
