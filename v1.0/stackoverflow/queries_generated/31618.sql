WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        1 AS Level,
        p.Title,
        p.CreationDate,
        Users.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users ON p.OwnerUserId = Users.Id
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        Level + 1,
        p.Title,
        p.CreationDate,
        Users.DisplayName
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
)

, PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    rph.PostId,
    rph.Title,
    rph.CreationDate,
    rph.OwnerDisplayName,
    ISNULL(pvs.UpVotes, 0) AS UpVotes,
    ISNULL(pvs.DownVotes, 0) AS DownVotes,
    rph.Level,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    CASE 
        WHEN rph.Level = 1 THEN 'Root Post'
        ELSE 'Child Post'
    END AS PostType,
    COUNT(c.Id) AS CommentCount,
    ROW_NUMBER() OVER (PARTITION BY rph.Level ORDER BY rph.CreationDate DESC) AS RowNum
FROM 
    RecursivePostHierarchy rph
LEFT JOIN 
    PostVoteSummary pvs ON rph.PostId = pvs.PostId
LEFT JOIN 
    PostLinks pl ON rph.PostId = pl.PostId
LEFT JOIN 
    Tags t ON pl.RelatedPostId = t.Id
LEFT JOIN 
    Comments c ON rph.PostId = c.PostId
GROUP BY 
    rph.PostId, rph.Title, rph.CreationDate, rph.OwnerDisplayName, rph.Level, pvs.UpVotes, pvs.DownVotes
HAVING 
    ISNULL(pvs.UpVotes, 0) + ISNULL(pvs.DownVotes, 0) > 0 -- Only include posts with votes
ORDER BY 
    rph.Level, RowNum;


