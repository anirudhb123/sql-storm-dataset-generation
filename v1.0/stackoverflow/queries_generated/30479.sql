WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        1 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.PostId
),

UserVoteStats AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN vt.Name = 'Close' THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN vt.Name = 'AcceptedByOriginator' THEN 1 END) AS AcceptedVotes
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),

PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        LATERAL string_to_array(p.Tags, ',') AS tag ON true
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
    GROUP BY 
        ph.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.Tags,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(vs.CloseVotes, 0) AS CloseVotes,
    COALESCE(vs.AcceptedVotes, 0) AS AcceptedVotes,
    pcs.EditCount,
    pcs.LastEditDate,
    COUNT(DISTINCT ph.UserId) AS EditContributors
FROM 
    Users u
JOIN 
    RecursivePostCTE ps ON ps.OwnerUserId = u.Id
LEFT JOIN 
    UserVoteStats vs ON vs.UserId = u.Id
LEFT JOIN 
    PostTags pt ON pt.PostId = ps.PostId
LEFT JOIN 
    PostHistoryStats pcs ON pcs.PostId = ps.PostId
LEFT JOIN 
    PostHistory ph ON ph.PostId = ps.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags edited
WHERE 
    ps.Depth = 1
GROUP BY 
    u.Id, u.DisplayName, ps.PostId, ps.Title, ps.CreationDate, ps.Score, pt.Tags, vs.UpVotes, vs.DownVotes, vs.CloseVotes, vs.AcceptedVotes, pcs.EditCount, pcs.LastEditDate
ORDER BY 
    ps.Score DESC, ps.CreationDate ASC;
