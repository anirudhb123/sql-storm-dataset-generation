
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(v.UpVotes - v.DownVotes, 0) AS NetVotes,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RankInType
    FROM 
        Posts p 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            ParentId, COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId) a ON a.ParentId = p.Id
    LEFT JOIN 
        (SELECT 
            PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
        FROM 
            Votes 
        GROUP BY 
            PostId) v ON v.PostId = p.Id
    JOIN 
        PostTypes pt ON pt.Id = p.PostTypeId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        GROUP_CONCAT(DISTINCT cr.Name ORDER BY cr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(cr.Id AS CHAR) = ph.Comment 
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.AnswerCount,
    rp.NetVotes,
    cp.FirstClosedDate,
    cp.CloseReasons
FROM 
    RankedPosts rp 
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId
WHERE 
    (rp.RankInType = 1 OR (cp.FirstClosedDate IS NOT NULL AND cp.FirstClosedDate < NOW() - INTERVAL 6 MONTH))
ORDER BY 
    rp.NetVotes DESC, 
    rp.CreationDate ASC
LIMIT 100;
