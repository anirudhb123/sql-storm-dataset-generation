WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate,
        CAST(p.Title AS varchar(300)) AS FullTitle,
        p.PostTypeId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId, 
        p.CreationDate,
        CAST(r.FullTitle + ' -> ' + p.Title AS varchar(300)),
        p.PostTypeId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
)

, TagAppearances AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'  -- Using LIKE to count occurrences in the Tags field
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 0
)

, UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
)

SELECT 
    p.PostId,
    p.FullTitle,
    p.OwnerUserId,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    t.TagName,
    tp.PostCount,
    CASE
        WHEN p.PostTypeId = 1 AND EXISTS (SELECT 1 FROM Posts a WHERE a.AcceptedAnswerId = p.PostId) THEN 'Has accepted answer'
        ELSE 'No accepted answer'
    END AS AcceptedAnswerStatus,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM 
    RecursivePostHierarchy p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON c.PostId = p.PostId
LEFT JOIN 
    PostLinks pl ON pl.PostId = p.PostId
LEFT JOIN 
    Votes v ON v.PostId = p.PostId AND v.VoteTypeId = 8  -- Only counting BountyStart votes
LEFT JOIN 
    TagAppearances tp ON tp.TagName IN (SELECT unnest(string_to_array(p.Tags, ',')))  -- Split tags and count appearances
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '7 days'  -- Limit to posts created in the last week
GROUP BY 
    p.PostId, p.FullTitle, u.DisplayName, u.Reputation, t.TagName, tp.PostCount
ORDER BY 
    p.PostId, u.Reputation DESC, tp.PostCount DESC;
