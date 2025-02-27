WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
    HAVING 
        COUNT(p.Id) > 5
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        CASE 
            WHEN EXISTS (SELECT 1 FROM Comments c WHERE c.PostId = rp.PostId) 
            THEN 'Has Comments' 
            ELSE 'No Comments' 
        END AS CommentStatus,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes 
        GROUP BY 
            PostId) v ON rp.PostId = v.PostId
    WHERE 
        rp.PostRank = 1
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    au.DisplayName,
    pd.CommentStatus,
    pd.UpVotes,
    pd.DownVotes,
    COALESCE(COUNT(DISTINCT b.Id), 0) AS BadgeCount
FROM 
    PostDetails pd
JOIN 
    ActiveUsers au ON pd.OwnerUserId = au.UserId
LEFT JOIN 
    Badges b ON au.UserId = b.UserId AND b.Class = 1
GROUP BY 
    pd.PostId, au.DisplayName, pd.Title, pd.CreationDate, pd.CommentStatus, pd.UpVotes, pd.DownVotes
HAVING 
    AVG(pd.UpVotes - pd.DownVotes) > 5
ORDER BY 
    pd.CreationDate DESC
LIMIT 10;
