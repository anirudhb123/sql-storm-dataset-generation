WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 1000 THEN 'Expert'
            WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate'
            ELSE 'Novice'
        END AS UserLevel
    FROM 
        Users u
), 
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        MAX(ph.CreationDate) AS LastModification
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ur.DisplayName,
    ur.Reputation,
    ur.UserLevel,
    pha.CloseReopenCount,
    pha.LastModification
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    PostHistoryAggregates pha ON rp.PostId = pha.PostId
WHERE 
    rp.Rank = 1
    AND rp.ViewCount > 100
    AND (ur.Reputation IS NOT NULL OR ur.UserLevel = 'Expert')
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
FETCH FIRST 50 ROWS ONLY;
