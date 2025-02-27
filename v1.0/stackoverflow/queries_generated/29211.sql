WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY t.TagName) AS TagRank
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN a.Id IS NOT NULL THEN a.Id END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1  -- Questions
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id  -- Answers
    GROUP BY 
        u.Id, u.DisplayName
),
TagPopularity AS (
    SELECT 
        ct.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedCount
    FROM 
        ProcessedTags ct
    JOIN 
        Posts p ON p.Id = ct.PostId
    GROUP BY 
        ct.TagName
),
FinalRanking AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.QuestionCount,
        u.AnswerCount,
        u.TotalViews,
        tp.TagName,
        tp.PostCount,
        tp.AcceptedCount,
        RANK() OVER (ORDER BY u.QuestionCount DESC, u.TotalViews DESC) AS UserRank
    FROM 
        UserPostStats u
    LEFT JOIN 
        TagPopularity tp ON tp.PostCount > 0
)

SELECT 
    UserRank,
    DisplayName,
    QuestionCount,
    AnswerCount,
    TotalViews,
    TagName,
    PostCount,
    AcceptedCount
FROM 
    FinalRanking
WHERE 
    UserRank <= 10
ORDER BY 
    UserRank, TagName;
