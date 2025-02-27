WITH RecursivePostCTE AS (
    -- Recursive CTE to gather all posts and their answers (if any)
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate AS PostCreationDate,
        p.ViewCount,
        p.Score,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions

    UNION ALL
    
    SELECT
        a.Id AS PostId,
        a.Title,
        a.PostTypeId,
        a.AcceptedAnswerId,
        a.CreationDate AS PostCreationDate,
        a.ViewCount,
        a.Score,
        r.Level + 1
    FROM 
        Posts a
    JOIN 
        RecursivePostCTE r ON a.ParentId = r.PostId
)

-- Main Query
SELECT 
    u.DisplayName AS PostOwner,
    COALESCE(b.Class, 0) AS BadgeClass,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.ViewCount DESC) AS PostRank,
    STRING_AGG(t.TagName, ', ') AS Tags,
    p.Title,
    r.Level AS AnswerLevel,
    r.PostCreationDate,
    r.ViewCount,
    r.Score,
    CASE 
        WHEN r.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted' 
    END AS AcceptanceStatus
FROM 
    RecursivePostCTE r
LEFT JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1  -- Gold badges
LEFT JOIN 
    Comments c ON r.PostId = c.PostId
LEFT JOIN 
    Votes v ON r.PostId = v.PostId
LEFT JOIN 
    STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '><') AS t ON p.Id = r.PostId
WHERE 
    u.Reputation > 1000 AND r.Score > 0  -- Only considering users with good reputation and posts with score
GROUP BY 
    u.DisplayName, b.Class, r.PostId, r.Title, r.PostCreationDate, r.ViewCount, r.Score, r.Level
ORDER BY 
    r.Score DESC, CommentCount DESC;
