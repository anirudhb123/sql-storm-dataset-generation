
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_owner_user_id := p.OwnerUserId,
        p.ViewCount,
        COALESCE(NULLIF(UPPER(p.Tags), ''), 'No Tags') AS NormalizedTags, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN 
        (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS init
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId, p.ViewCount, p.Tags
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        @user_rank := @user_rank + 1 AS UserRank
    FROM 
        Users u
    CROSS JOIN 
        (SELECT @user_rank := 0) AS init
    WHERE 
        u.LastAccessDate >= '2024-10-01 12:34:56' - INTERVAL 3 MONTH
    ORDER BY 
        u.Reputation DESC
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserId AS EditorUserId,
        ph.Comment,
        GROUP_CONCAT(COALESCE(pht.Name, 'Unknown') SEPARATOR ', ') AS HistoryTypeNames
    FROM 
        PostHistory ph
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate, ph.UserId, ph.Comment
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    ph.HistoryTypeNames,
    ph.HistoryDate,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.PostId END) AS ClosePostCount,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.PostId END) AS ReopenPostCount
FROM 
    RankedPosts rp
JOIN 
    ActiveUsers u ON rp.OwnerUserId = u.UserId
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
WHERE 
    rp.PostRank = 1
    AND rp.ViewCount > 10
    AND u.Reputation BETWEEN 100 AND 1000
    AND (ph.PostHistoryTypeId IS NULL OR ph.HistoryDate >= '2024-10-01 12:34:56' - INTERVAL 6 MONTH)
GROUP BY 
    rp.PostId, rp.Title, rp.Score, rp.CommentCount, u.DisplayName, u.Reputation, ph.HistoryTypeNames, ph.HistoryDate
ORDER BY 
    rp.Score DESC, u.Reputation DESC
LIMIT 100;
