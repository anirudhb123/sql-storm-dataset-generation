WITH RECURSIVE RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        rp.Depth + 1
    FROM 
        Posts p
    INNER JOIN RecentPosts rp ON p.ParentId = rp.Id
)
, PostVotes AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
, UserReputation AS (
    SELECT 
        u.Id AS UserId,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id
)
, PostsWithVotes AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(pv.UpVotes, 0) AS UpVotes,
        COALESCE(pv.DownVotes, 0) AS DownVotes,
        COALESCE(u.AvgReputation, 0) AS AvgUserReputation
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostVotes pv ON rp.Id = pv.PostId
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
)

SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.UpVotes,
    p.DownVotes,
    p.AvgUserReputation,
    CASE 
        WHEN p.Score >= 10 THEN 'Popular'
        WHEN p.Score BETWEEN 5 AND 9 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS Popularity,
    COUNT(c.Id) AS CommentCount
FROM 
    PostsWithVotes p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Title, p.CreationDate, p.Score, p.UpVotes, p.DownVotes, p.AvgUserReputation
HAVING 
    SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END) > 0
ORDER BY 
    p.CreationDate DESC, p.Score DESC
LIMIT 100;
