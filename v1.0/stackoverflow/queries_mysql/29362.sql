
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS RankByScore,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        (SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT @row := @row + 1 AS n FROM 
                (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t1,
                (SELECT @row := 0) t2) numbers
        WHERE 
            numbers.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) t ON TRUE
    WHERE 
        p.PostTypeId = 1 
),

QuestionStatistics AS (
    SELECT 
        TagName,
        COUNT(PostId) AS QuestionCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AvgScore,
        AVG(AnswerCount) AS AvgAnswerCount
    FROM 
        RankedPosts
    GROUP BY 
        TagName
),

TopQuestions AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Author,
        TagName
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5
)

SELECT 
    qs.TagName,
    qs.QuestionCount,
    qs.TotalViews,
    qs.AvgScore,
    qs.AvgAnswerCount,
    tq.Title AS TopQuestionTitle,
    tq.CreationDate AS TopQuestionDate,
    tq.Author AS TopQuestionAuthor
FROM 
    QuestionStatistics qs
LEFT JOIN 
    TopQuestions tq ON qs.TagName = tq.TagName
ORDER BY 
    qs.QuestionCount DESC, 
    qs.TotalViews DESC;
