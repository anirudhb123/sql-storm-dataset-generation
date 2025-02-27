WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
), PostDetail AS (
    SELECT 
        rp.Title,
        rp.Score,
        rp.ViewCount,
        ur.Reputation,
        ur.BadgeCount,
        CASE 
            WHEN rp.CommentCount > 0 THEN 'Has Comments' 
            ELSE 'No Comments' 
        END AS CommentStatus
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.RowNum = 1
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.Reputation,
    pd.BadgeCount,
    pd.CommentStatus
FROM 
    PostDetail pd
WHERE 
    pd.Score > (SELECT AVG(Score) FROM Posts)
ORDER BY 
    pd.Score DESC
LIMIT 10;

-- Combine with votes information
UNION ALL 

SELECT 
    p.Title,
    SUM(v.BountyAmount) AS TotalBounty,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    'Vote Summary' AS CommentStatus
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 -- Only Questions
GROUP BY 
    p.Title
HAVING 
    TotalBounty IS NOT NULL OR COUNT(v.Id) > 0
ORDER BY 
    TotalBounty DESC
LIMIT 5;
