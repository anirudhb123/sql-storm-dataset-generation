WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart votes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.AverageBounty,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank = 1
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.Score,
    pd.CommentCount,
    pd.AverageBounty,
    pd.UpVotes,
    pd.DownVotes,
    CASE 
        WHEN pd.Score >= 10 THEN 'High Score'
        WHEN pd.Score BETWEEN 5 AND 9 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 0
ORDER BY 
    pd.Score DESC, pd.CommentCount DESC
LIMIT 100;

-- Also display posts that might have been closed without comments
UNION ALL

SELECT 
    p.Id AS PostId,
    p.Title,
    'N/A' AS OwnerDisplayName,
    p.CreationDate,
    p.Score,
    0 AS CommentCount,
    0 AS AverageBounty,
    0 AS UpVotes,
    0 AS DownVotes,
    'Closed Post' AS ScoreCategory
FROM 
    Posts p
WHERE 
    p.ClosedDate IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM Comments c WHERE c.PostId = p.Id)
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
