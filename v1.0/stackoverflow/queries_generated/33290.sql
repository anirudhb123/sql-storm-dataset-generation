WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.ViewCount,
        CAST(1 AS int) AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.ViewCount,
        r.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts r ON p.ParentId = r.Id
),
RecentUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.CreationDate DESC) AS RN
    FROM 
        Users u
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '30 days'
),
PostStatistics AS (
    SELECT 
        rp.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        AVG(UPPER(SUBSTRING(rp.Title, 1, 5))) AS AvgTitleLength  -- Using a string function for example
    FROM 
        RecursivePosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.Id
    LEFT JOIN 
        Votes v ON v.PostId = rp.Id
    GROUP BY 
        rp.Id
)
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Owner,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.AvgTitleLength,
    COALESCE(NULLIF(rp.Depth, 0), 1) AS AnswerDepth, -- Handling NULL logic for depth
    CASE 
        WHEN ps.CommentCount > 5 THEN 'High Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel
FROM 
    PostStatistics ps
JOIN 
    Posts p ON p.Id = ps.PostId
JOIN 
    Users u ON u.Id = p.OwnerUserId
LEFT JOIN 
    RecursivePosts rp ON rp.Id = p.Id
WHERE 
    (p.CreationDate >= NOW() - INTERVAL '1 YEAR' AND ps.CommentCount > 0)
    OR (p.ViewCount > 100 AND ps.UpVoteCount > ps.DownVoteCount)
ORDER BY 
    ps.UpVoteCount DESC, ps.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;  -- Performance benchmarking size
