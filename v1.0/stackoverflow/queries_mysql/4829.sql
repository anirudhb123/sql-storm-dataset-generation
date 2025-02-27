
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(u.Reputation) AS AvgReputation,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS QuestionsAsked,
        AVG(p.ViewCount) AS AvgViews,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p
    INNER JOIN 
        (SELECT @rownum := @rownum + 1 AS n FROM 
          (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
           UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 
           UNION SELECT 9 UNION SELECT 10) numbers, 
          (SELECT @rownum := 0) r) numbers ON CHAR_LENGTH(p.Tags) - 
          CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        Tag
    HAVING 
        COUNT(p.Id) > 10
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.AvgReputation,
    qs.QuestionsAsked,
    qs.AvgViews,
    qs.TotalComments,
    pt.Tag AS PopularTag,
    pt.TagCount
FROM 
    UserStats us
LEFT JOIN 
    QuestionStats qs ON us.UserId = qs.OwnerUserId
LEFT JOIN 
    PopularTags pt ON pt.Tag IN (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = us.UserId
    )
WHERE 
    us.TotalPosts > 5
ORDER BY 
    us.AvgReputation DESC
LIMIT 50;
