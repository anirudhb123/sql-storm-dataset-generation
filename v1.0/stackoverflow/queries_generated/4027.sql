WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
)
SELECT 
    u.DisplayName,
    COUNT(rp.Id) AS TotalPosts,
    AVG(rp.Score) AS AvgScore,
    SUM(rp.CommentCount) AS TotalComments,
    SUM(rp.UpVotes) AS TotalUpVotes
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(rp.Id) > 5
ORDER BY 
    TotalPosts DESC
FETCH FIRST 10 ROWS ONLY;

WITH TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    GROUP BY 
        t.TagName
)
SELECT 
    tu.TagName,
    tu.PostCount,
    tu.UpVotes,
    CASE 
        WHEN tu.PostCount > 50 THEN 'Highly Used'
        WHEN tu.PostCount BETWEEN 20 AND 50 THEN 'Moderately Used'
        ELSE 'Less Used'
    END AS UsageCategory
FROM 
    TagUsage tu
WHERE 
    tu.PostCount > 10
ORDER BY 
    tu.PostCount DESC;

SELECT 
    p.Title AS PostTitle,
    ph.UserDisplayName,
    ph.CreationDate,
    ph.Comment,
    ph.CreationDate AS UpdateDate
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    ph.PostHistoryTypeId IN (4, 5) -- 'Edit Title', 'Edit Body'
    AND ph.CreationDate >= DATEADD(month, -6, GETDATE())
ORDER BY 
    ph.CreationDate DESC;

SELECT 
    p.Title AS QuestionTitle,
    COUNT(a.Id) AS TotalAnswers
FROM 
    Posts p
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
WHERE 
    p.PostTypeId = 1
GROUP BY 
    p.Id, p.Title
HAVING 
    COUNT(a.Id) >= 5
ORDER BY 
    TotalAnswers DESC;

SELECT 
    DISTINCT p.Tags,
    COUNT(DISTINCT p.Id) AS PostCount
FROM 
    Posts p
WHERE 
    p.ViewCount IS NOT NULL AND p.ViewCount > 1000
GROUP BY 
    p.Tags
HAVING 
    COUNT(DISTINCT p.Id) > 1;
