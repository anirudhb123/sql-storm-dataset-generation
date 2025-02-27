WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts pt ON pt.Tags LIKE CONCAT('%', t.TagName, '%') -- assuming Tags are comma-separated
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    ph.Level,
    ph.Title,
    ph.CreationDate,
    tt.TagName,
    tt.PostCount
FROM 
    UserPostStats u
LEFT JOIN 
    RecursivePostHierarchy ph ON ph.PostId IN (SELECT ParentId FROM Posts WHERE OwnerUserId = u.UserId)
LEFT JOIN 
    TopTags tt ON tt.TagName IN (SELECT unnest(string_to_array(LEFT(p.Tags, LENGTH(p.Tags) - 1), ',')) FROM Posts p WHERE p.OwnerUserId = u.UserId)
WHERE 
    u.TotalPosts > 0
ORDER BY 
    u.TotalPosts DESC,
    tt.PostCount DESC
LIMIT 50;
