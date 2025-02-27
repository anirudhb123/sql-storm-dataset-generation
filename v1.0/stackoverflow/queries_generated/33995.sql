WITH RecursivePostTree AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        pt.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostTree pt ON p.ParentId = pt.PostId
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT rp.PostId) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN rp.Level = 1 THEN rp.PostId END) AS TopLevelQuestions,
    COUNT(DISTINCT CASE WHEN rp.Level > 1 THEN rp.PostId END) AS NestedAnswers,
    SUM(COALESCE(po.ViewCount, 0)) AS TotalViews,
    SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
    SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    RecursivePostTree rp ON rp.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (2, 3)  -- Upvotes and Downvotes
LEFT JOIN 
    UNNEST(string_to_array(p.Tags, '><')) AS t ON p.Tags IS NOT NULL  -- Handling tags
LEFT JOIN 
    (
        SELECT 
            PostId, 
            SUM(ViewCount) AS ViewCount 
        FROM 
            Posts 
        GROUP BY 
            PostId
    ) po ON po.PostId = p.Id
GROUP BY 
    u.Id
ORDER BY 
    TotalQuestions DESC
LIMIT 10;
