WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score,
        COALESCE(rp.CommentCount, 0) AS CommentCount,
        tu.DisplayName AS OwnerName,
        tu.UserRank
    FROM 
        RankedPosts rp
    JOIN 
        TopUsers tu ON tu.UserId = rp.OwnerUserId
    WHERE 
        rp.PostRank = 1 AND tu.UserRank <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.CommentCount,
    fp.OwnerName,
    CASE 
        WHEN fp.CommentCount > 0 THEN 'Has Comments' 
        ELSE 'No Comments' 
    END AS Comment_Status,
    NULLIF(fp.Score, 0) AS NonZeroScore
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.OwnerName ASC;
