
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        @row_num := IF(@prev_owner_id = p.OwnerUserId, @row_num + 1, 1) AS Rank,
        @prev_owner_id := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    CROSS JOIN (SELECT @row_num := 0, @prev_owner_id := NULL) AS init
    WHERE 
        p.CreationDate < '2024-10-01 12:34:56'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        pt.Name AS HistoryType,
        @history_row_num := IF(@history_prev_post_id = ph.PostId, @history_row_num + 1, 1) AS HistoryRank,
        @history_prev_post_id := ph.PostId
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON pt.Id = ph.PostHistoryTypeId
    CROSS JOIN (SELECT @history_row_num := 0, @history_prev_post_id := NULL) AS init
)

SELECT 
    up.DisplayName,
    up.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    up.TotalBadges,
    rp.Upvotes,
    rp.Downvotes,
    (
        SELECT GROUP_CONCAT(HT.HistoryType SEPARATOR ', ') 
        FROM PostHistoryDetails HT 
        WHERE HT.PostId = rp.PostId AND HT.HistoryRank <= 5 
    ) AS RecentHistoryTypes,
    LEAD(rp.Score) OVER (ORDER BY rp.CreationDate) AS NextPostScore,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        WHEN rp.Score = 0 THEN 'Neutral'
        WHEN rp.Score > 0 THEN 'Positive'
        ELSE 'Negative' 
    END AS ScoreCategory,
    @global_row_num := @global_row_num + 1 AS GlobalRank
FROM 
    RankedPosts rp
JOIN 
    UserReputation up ON up.UserId = rp.OwnerUserId
CROSS JOIN (SELECT @global_row_num := 0) AS init
WHERE 
    up.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND rp.Rank = 1 
ORDER BY 
    rp.Score DESC, up.Reputation DESC
LIMIT 50 OFFSET 0;
