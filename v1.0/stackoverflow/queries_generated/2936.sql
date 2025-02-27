WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        COALESCE(po.RevisionCount, 0) AS RevisionCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as rn
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS RevisionCount
        FROM 
            PostHistory
        GROUP BY 
            PostId
    ) po ON p.Id = po.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
)

SELECT 
    rp.Title,
    u.DisplayName,
    u.Reputation,
    u.Views,
    rp.CreationDate,
    CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question'
        WHEN rp.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    rp.RevisionCount,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    RecentPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON rp.Id = c.PostId
LEFT JOIN 
    Votes v ON rp.Id = v.PostId
WHERE 
    rp.rn = 1
GROUP BY 
    rp.Title, u.DisplayName, u.Reputation, u.Views, rp.CreationDate, rp.PostTypeId, rp.RevisionCount
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;

-- Additional Queries
SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS PostCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
HAVING 
    COUNT(p.Id) > 10
ORDER BY 
    PostCount DESC;

SELECT DISTINCT
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    UNNEST(STRING_TO_ARRAY(p.Tags, '>')) AS t(TagName)
WHERE 
    p.ViewCount > 1000
    AND p.CreationDate < (CURRENT_DATE - INTERVAL '1 year');

-- Exclude posts with specific criteria
SELECT 
    p.Id,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvotes and downvotes
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM PostHistory ph 
        WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 12) -- Closed or deleted
    )
GROUP BY 
    p.Id
HAVING 
    COUNT(v.Id) > 0
ORDER BY 
    VoteCount DESC;
