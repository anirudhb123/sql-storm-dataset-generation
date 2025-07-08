
WITH TagFrequency AS (
    SELECT 
        SPLIT(TRIM(BOTH '<>' FROM Tags), '><') AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tags
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionsAsked,
        SUM(COALESCE(p.AnswerCount, 0)) AS AnswersReceived,
        SUM(COALESCE(c.Id, 0)) AS CommentsMade,
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
        t.Tag,
        COUNT(DISTINCT p.Id) AS PostsAssociated,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(c.Id, 0)) AS TotalComments
    FROM
        TagFrequency t
    JOIN
        Posts p ON p.Tags LIKE '%>' || t.Tag || '<%'
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY
        t.Tag
)
SELECT 
    tu.DisplayName,
    tu.QuestionsAsked,
    tu.AnswersReceived,
    tu.CommentsMade,
    tu.VotesReceived,
    tp.Tag,
    tp.PostsAssociated,
    tp.TotalAnswers,
    tp.TotalComments
FROM 
    TopUsers tu
JOIN 
    TagPerformance tp ON tu.UserId = (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Tags LIKE '%' || tp.Tag || '%'
        LIMIT 1
    )
WHERE 
    tu.RankByQuestions <= 10 OR tu.RankByAnswers <= 10 OR tu.RankByComments <= 10
ORDER BY 
    tu.RankByQuestions, tu.RankByAnswers, tu.RankByComments;
