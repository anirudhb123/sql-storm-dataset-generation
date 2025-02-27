WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
HighScoringPosts AS (
    SELECT 
        rp.*, 
        (UpVotes - DownVotes) AS NetVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score > 10
),
RecentHighScoringPosts AS (
    SELECT 
        hsp.*,
        RANK() OVER (PARTITION BY hsp.OwnerUserId ORDER BY hsp.CreationDate DESC) AS UserPostRank
    FROM 
        HighScoringPosts hsp
)
SELECT 
    p.Id,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.OwnerDisplayName,
    p.NetVotes
FROM 
    RecentHighScoringPosts p
WHERE 
    p.UserPostRank = 1
ORDER BY 
    p.NetVotes DESC, 
    p.CreationDate DESC
LIMIT 10
UNION ALL
SELECT 
    p.Id,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.OwnerDisplayName,
    0 AS NetVotes
FROM 
    Posts p
WHERE 
    p.ViewCount < 50
    AND NOT EXISTS (
        SELECT 1 
        FROM Posts p2 
        WHERE p2.OwnerUserId = p.OwnerUserId AND p2.Id != p.Id AND p2.ViewCount >= 50
    )
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
