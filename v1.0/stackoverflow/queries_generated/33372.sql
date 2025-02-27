WITH RecursivePostHierarchy AS (
    -- Recursive CTE to get all answers for each question, along with the score and user details
    SELECT 
        p.Id AS PostId,
        p.Title AS QuestionTitle,
        p.Score AS QuestionScore,
        u.DisplayName AS QuestionOwner,
        p.CreationDate AS QuestionDate,
        0 AS Level,
        NULL AS AnswerId,
        NULL AS AnswerScore,
        NULL AS AnswerOwner,
        NULL AS AnswerDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        p.Id AS PostId,
        ph.QuestionTitle,
        ph.QuestionScore,
        ph.QuestionOwner,
        ph.QuestionDate,
        ph.Level + 1 AS Level,
        p.Id AS AnswerId,
        p.Score AS AnswerScore,
        u.DisplayName AS AnswerOwner,
        p.CreationDate AS AnswerDate
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 2 -- Answers only
), RankedPosts AS (
    -- Rank questions based on their scores and the number of answers they have received
    SELECT 
        ph.PostId,
        ph.QuestionTitle,
        ph.QuestionScore,
        ph.QuestionOwner,
        ph.QuestionDate,
        COUNT(ph.AnswerId) AS TotalAnswers,
        RANK() OVER (ORDER BY ph.QuestionScore DESC, COUNT(ph.AnswerId) DESC) AS Rank
    FROM 
        RecursivePostHierarchy ph
    GROUP BY 
        ph.PostId, ph.QuestionTitle, ph.QuestionScore, ph.QuestionOwner, ph.QuestionDate
), PopularTags AS (
    -- Identify the most popular tags based on question count and upvotes
    SELECT 
        unnest(string_to_array(p.Tags, ',')) AS Tag, 
        COUNT(*) AS TagCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        unnest(string_to_array(p.Tags, ','))
    ORDER BY 
        TagCount DESC, TotalScore DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.QuestionTitle,
    rp.QuestionScore,
    rp.QuestionOwner,
    rp.QuestionDate,
    rp.TotalAnswers,
    pt.Tag AS PopularTag,
    pt.TagCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.Tag = ANY(string_to_array(rp.QuestionTitle, ' ')) -- Assuming tags are part of the title for demo purposes
WHERE 
    rp.Rank <= 10 -- Top 10 ranked questions
ORDER BY 
    rp.QuestionScore DESC, rp.TotalAnswers DESC;

-- Additional metrics for performance evaluation
SELECT 
    COUNT(DISTINCT rp.PostId) AS TotalQuestions,
    SUM(rp.QuestionScore) AS TotalScore,
    AVG(rp.QuestionScore) AS AverageScore,
    SUM(rp.TotalAnswers) AS TotalAnswers
FROM 
    RankedPosts rp;
