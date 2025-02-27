
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT n1.n + n2.n * 10 n FROM 
            (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
             SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) n1,
            (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
             SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) n2 
        ) n 
        ON n.n <= (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '>', '')) + 1) 
    WHERE 
        p.PostTypeId = 1 
),
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS NumberOfQuestions
    FROM 
        Tags t
    JOIN 
        PostTags pt ON t.TagName = pt.Tag
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        NumberOfQuestions,
        (SELECT COUNT(*) FROM TagUsage WHERE NumberOfQuestions > tu.NumberOfQuestions) + 1 AS TagRank
    FROM 
        TagUsage tu
    WHERE 
        NumberOfQuestions > 10 
),
MostPopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND p.Score > 5 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
BestAnswers AS (
    SELECT 
        p.AcceptedAnswerId AS AnswerId,
        p.Title AS AnswerTitle,
        u.DisplayName AS UserName,
        p.Score AS AnswerScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 2 
),
FinalResults AS (
    SELECT 
        tt.TagName,
        tp.Title AS QuestionTitle,
        tp.Score AS QuestionScore,
        tp.ViewCount AS QuestionViews,
        mp.AnswerId,
        mp.AnswerTitle,
        mp.UserName AS AnsweredBy,
        mp.AnswerScore AS AnswerScore
    FROM 
        TopTags tt
    JOIN 
        MostPopularPosts tp ON EXISTS (
            SELECT 1 FROM PostTags pt WHERE pt.PostId = tp.Id AND pt.Tag = tt.TagName
        )
    LEFT JOIN 
        BestAnswers mp ON tp.Id = (SELECT AcceptedAnswerId FROM Posts p WHERE p.Id = tp.Id)
)

SELECT 
    TagName,
    QuestionTitle,
    QuestionScore,
    QuestionViews,
    AnswerId,
    AnswerTitle,
    AnsweredBy,
    AnswerScore
FROM 
    FinalResults
ORDER BY 
    TagName, 
    QuestionScore DESC;
