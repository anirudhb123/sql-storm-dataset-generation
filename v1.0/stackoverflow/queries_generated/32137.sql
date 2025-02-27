WITH RecursivePostCTE AS (
    -- Recursive CTE to fetch all answers related to questions
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2 -- Answers
),
TopTags AS (
    -- Fetch top 5 tags based on usage count
    SELECT 
        t.Id,
        t.TagName,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM 
        Tags t
    INNER JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int[]
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        t.Id, t.TagName
    ORDER BY 
        TotalAnswers DESC
    LIMIT 5
),
UserActivity AS (
    -- Summarize user activity
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000  -- Users with more than 1000 reputation
    GROUP BY 
        u.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalScore,
    u.TotalComments,
    u.TotalBadges,
    ARRAY_AGG(t.TagName) AS PopularTags,
    COUNT(DISTINCT r.PostId) AS RelatedAnswers
FROM 
    UserActivity u
LEFT JOIN 
    TopTags t ON TRUE
LEFT JOIN 
    RecursivePostCTE r ON u.UserId = r.OwnerUserId
WHERE 
    u.TotalPosts > 0
GROUP BY 
    u.UserId
ORDER BY 
    u.TotalScore DESC, 
    u.DisplayName ASC;
