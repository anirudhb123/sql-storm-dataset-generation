WITH RecursiveVoteCount AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
CTE_PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        pht.Name AS PostHistoryType,
        COALESCE(uv.TotalVotes, 0) AS UserVoteCount,
        COALESCE(uv.UpVotes, 0) AS UpVoteCount,
        COALESCE(uv.DownVotes, 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS MostRecentEdit
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    LEFT JOIN 
        RecursiveVoteCount uv ON p.Id = uv.PostId
    WHERE 
        p.ViewCount > 0
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        PostHistoryType,
        UserVoteCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        CTE_PostDetails
    WHERE 
        UpVoteCount > DownVoteCount
)

SELECT 
    f.PostId,
    f.Title,
    f.Score,
    f.PostHistoryType,
    f.UserVoteCount,
    ROUND((f.UpVoteCount::decimal / NULLIF(f.UserVoteCount, 0)) * 100, 2) AS UpVotePercentage
FROM 
    FilteredPosts f
WHERE 
    f.MostRecentEdit = 1
ORDER BY 
    f.Score DESC, f.UserVoteCount DESC
LIMIT 10

UNION ALL

SELECT 
    p.Id AS PostId,
    'N/A' AS Title,
    0 AS Score,
    'No Activity' AS PostHistoryType,
    0 AS UserVoteCount,
    0 AS UpVoteCount,
    0 AS DownVoteCount,
    NULL AS UpVotePercentage
FROM 
    Posts p
WHERE 
    NOT EXISTS (
        SELECT 1 FROM Votes v WHERE v.PostId = p.Id
    )
AND 
    p.ViewCount = 0
ORDER BY 
    p.Id DESC
LIMIT 5;
