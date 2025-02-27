-- Performance Benchmarking Query for StackOverflow Schema

-- This query calculates the average time taken for users to receive their first upvote
-- after they have posted a question, along with the total number of questions asked by each user.

WITH UserFirstUpvote AS (
    SELECT 
        p.OwnerUserId,
        MIN(v.CreationDate) AS FirstUpvoteDate
    FROM 
        Posts p
    JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only considering Questions
        AND v.VoteTypeId = 2  -- Only Upvotes
    GROUP BY 
        p.OwnerUserId
),
UserQuestionDetails AS (
    SELECT
        u.Id AS UserId,
        COUNT(p.Id) AS TotalQuestions,
        MIN(p.CreationDate) AS FirstQuestionDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        u.Id
)
SELECT 
    u.UserId,
    u.TotalQuestions,
    COALESCE(DATEDIFF(uf.FirstUpvoteDate, u.FirstQuestionDate), 0) AS DaysToFirstUpvote
FROM 
    UserQuestionDetails u
LEFT JOIN 
    UserFirstUpvote uf ON u.UserId = uf.OwnerUserId
WHERE 
    u.TotalQuestions > 0  -- Filter users who have posted questions
ORDER BY 
    DaysToFirstUpvote ASC;
