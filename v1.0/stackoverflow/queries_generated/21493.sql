WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
ClosePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(AVG(v.BountyAmount), 0) AS AverageBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.CommentCount,
        COALESCE(ch.CreationDate, '1900-01-01'::timestamp) AS LastCloseDate -- Default to an old date if NULL
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosePostHistory ch ON rp.PostId = ch.PostId
    WHERE
        rp.RankScore <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.CommentCount,
    fp.LastCloseDate,
    ur.DisplayName AS OwnerDisplayName,
    ur.Reputation AS OwnerReputation,
    ur.AverageBounty
FROM 
    FilteredPosts fp
JOIN 
    Users ur ON fp.OwnerUserId = ur.Id
WHERE 
    (FOOTER.CommentCount > 0 OR fp.LastCloseDate > (NOW() - INTERVAL '30 days')) 
ORDER BY 
    fp.Score DESC, fp.LastCloseDate ASC
LIMIT 50
OFFSET (SELECT FLOOR(RANDOM() * COUNT(*)) FROM FilteredPosts);
