WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        rph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) as CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
)
SELECT 
    rph.PostId,
    rph.Title,
    COALESCE(pvc.UpVotes, 0) AS UpVotes,
    COALESCE(pvc.DownVotes, 0) AS DownVotes,
    COALESCE(pwc.CommentCount, 0) AS CommentCount,
    rph.Level,
    CASE 
        WHEN rph.Level = 0 THEN 'Root Post'
        WHEN rph.Level = 1 THEN 'Child Post'
        ELSE 'Grandchild Post'
    END AS PostHierarchyLevel
FROM 
    RecursivePostHierarchy rph
LEFT JOIN 
    PostVotes pvc ON rph.PostId = pvc.PostId
LEFT JOIN 
    PostWithComments pwc ON rph.PostId = pwc.PostId
ORDER BY 
    rph.Level, rph.Title;
