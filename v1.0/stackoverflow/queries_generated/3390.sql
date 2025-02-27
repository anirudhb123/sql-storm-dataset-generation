WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 DAY'
    GROUP BY 
        p.Id
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
), 
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        pht.Name AS HistoryType,
        ph.UserDisplayName,
        ph.Text AS EditDescription
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(rp.ViewCount, 0) AS ViewCount,
    rp.CommentCount,
    ur.DisplayName AS OwnerDisplayName,
    ur.Reputation,
    ur.ReputationRank,
    ph.HistoryDate,
    ph.HistoryType,
    ph.UserDisplayName AS EditorDisplayName,
    ph.EditDescription
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
WHERE 
    (ph.HistoryType IS NULL OR ph.HistoryDate >= NOW() - INTERVAL '7 DAY')
ORDER BY 
    rp.OwnerPostRank, 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 100;
