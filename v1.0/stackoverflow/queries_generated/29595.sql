WITH RecentPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        u.DisplayName as Owner,
        COUNT(a.Id) as AnswerCount,
        ARRAY_AGG(DISTINCT t.TagName) as Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '>')) AS tag ON true
    JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag)
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
    HAVING 
        COUNT(a.Id) > 0 -- At least one answer
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
    ORDER BY 
        u.Reputation DESC
    LIMIT 10 -- Top 10 users by reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.AnswerCount,
    rp.Owner,
    tu.DisplayName AS TopContributor,
    tu.Reputation AS ContributorReputation,
    rp.Tags
FROM 
    RecentPosts rp
JOIN 
    TopUsers tu ON rp.Owner = tu.DisplayName
ORDER BY 
    rp.CreationDate DESC;
