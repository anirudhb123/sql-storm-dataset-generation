
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        @rownum := IF(@prevOwnerUserId = p.OwnerUserId, @rownum + 1, 1) AS PostRank,
        @prevOwnerUserId := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @rownum := 0, @prevOwnerUserId := NULL) AS vars
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
PostHistoryWithComments AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        @historyRank := IF(@prevPostId = ph.PostId, @historyRank + 1, 1) AS HistoryRank,
        @prevPostId := ph.PostId
    FROM 
        PostHistory ph
    CROSS JOIN (SELECT @historyRank := 0, @prevPostId := NULL) AS vars
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        @reputationRank := @reputationRank + 1 AS ReputationRank
    FROM 
        Users u
    CROSS JOIN (SELECT @reputationRank := 0) AS vars
    WHERE 
        u.Reputation IS NOT NULL
    ORDER BY 
        u.Reputation DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpVoteCount - rp.DownVoteCount AS NetVotes,
    COALESCE(ph.Comment, 'No recent action') AS RecentAction,
    ur.Reputation,
    ur.ReputationRank
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryWithComments ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1
LEFT JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE 
    rp.Score > 0 
    AND DATEDIFF('2024-10-01', rp.CreationDate) <= 30
    AND (rp.CommentCount > 5 OR ur.Reputation > 1000)
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 50;
