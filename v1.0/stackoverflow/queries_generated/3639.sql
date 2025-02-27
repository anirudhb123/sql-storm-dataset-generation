WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(ph.RevisionCount, 0) AS RevisionCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(Id) AS RevisionCount
        FROM 
            PostHistory
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    u.DisplayName AS OwnerName,
    uv.UpVotes,
    uv.DownVotes,
    pd.RevisionCount,
    pd.PostRank,
    CASE 
        WHEN pd.PostRank = 1 THEN 'Latest Post by User' 
        ELSE 'Earlier Post by User' 
    END AS PostStatus,
    SUM(CASE 
        WHEN v.VoteTypeId = 6 THEN 1 
        ELSE 0 
    END) OVER (PARTITION BY pd.PostId) AS CloseVoteCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PostDetails pd
JOIN 
    Users u ON pd.OwnerUserId = u.Id
LEFT JOIN 
    UserVotes uv ON u.Id = uv.UserId
LEFT JOIN 
    Posts p2 ON pd.PostId = p2.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = pd.PostId
LEFT JOIN 
    Votes v ON v.PostId = pd.PostId AND v.VoteTypeId = 6
WHERE 
    pd.PostRank <= 5 
    AND (pd.CreationDate >= NOW() - INTERVAL '3 months' OR uv.TotalVotes > 0)
GROUP BY 
    pd.PostId, pd.Title, pd.CreationDate, u.DisplayName, uv.UpVotes, uv.DownVotes, pd.RevisionCount, pd.PostRank
ORDER BY 
    pd.RevisionCount DESC, uv.UpVotes DESC;
