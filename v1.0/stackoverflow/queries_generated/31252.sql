WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
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
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
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
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        ph.PostId, ph.UserId, ph.PostHistoryTypeId
)
SELECT 
    p.PostId,
    p.Title,
    p.Score,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    tu.Reputation AS OwnerReputation,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    tu.UserRank,
    COALESCE(SUM(ph.HistoryCount), 0) AS PostEditHistoryCount,
    CASE 
        WHEN p.Rank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    TopUsers tu ON u.Id = tu.UserId
LEFT JOIN 
    PostHistoryCTE ph ON p.PostId = ph.PostId
WHERE 
    p.Score > 10  -- Only considering posts with score greater than 10
GROUP BY 
    p.PostId, p.Title, p.Score, p.CreationDate, u.DisplayName, tu.Reputation, tu.UserRank, p.Rank
ORDER BY 
    p.Score DESC, OwnerReputation DESC
LIMIT 50;
