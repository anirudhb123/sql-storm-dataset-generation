WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),

TopQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS QuestionRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),

PopularTags AS (
    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        COUNT(p.Id) AS PostsCount,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS PopularityCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName, t.Count
    HAVING 
        COUNT(p.Id) >= 10
)

SELECT 
    u.DisplayName AS User,
    q.Title AS TopQuestion,
    q.CreationDate AS QuestionDate,
    q.Score AS QuestionScore,
    q.ViewCount AS QuestionViews,
    t.TagName AS PopularTag,
    t.PostsCount AS TagPostCount,
    t.PopularityCount AS PopularityViews
FROM 
    RankedUsers u
JOIN 
    TopQuestions q ON u.UserId = q.OwnerUserId AND q.QuestionRank = 1
LEFT JOIN 
    PopularTags t ON t.PostsCount > 0
WHERE 
    u.Rank <= 50 
    AND (t.PopularityCount IS NULL OR t.PopularityCount > 5)
ORDER BY 
    u.Rank, q.Score DESC;

-- This query aggregates various statistics: it ranks users based on their reputation,
-- filters for the top question from each user, and pulls popular tags related to those questions.
-- It uses window functions to rank and filter, correlated subqueries to determine view counts,
-- and left joins to connect various related data, applying complicated predicates 
-- to fine-tune the results for performance benchmarking.
