WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 0
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Comment,
        ph.UserId,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Close, Reopen, Deleted
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) - SUM(u.DownVotes) AS NetVotes,
        RANK() OVER (ORDER BY SUM(u.UpVotes) - SUM(u.DownVotes) DESC) AS UserRank
    FROM 
        Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '2 years'
    GROUP BY u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerName,
    u.Reputation AS OwnerReputation,
    th.PostHistoryTypeId,
    th.Comment AS HistoryComment,
    th.UserDisplayName AS ModifierName,
    th.CreationDate AS HistoryDate,
    tu.NetVotes,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Post"
        WHEN rp.Rank = 2 THEN 'Second Best Post'
        ELSE CONCAT(rp.Rank, 'th Best Post')
    END AS PostRanking,
    COALESCE((SELECT COUNT(*)
              FROM Comments c 
              WHERE c.PostId = rp.PostId), 0) AS CommentCount,
    COALESCE(NULLIF((SELECT AVG(v.BountyAmount)
                     FROM Votes v 
                     WHERE v.PostId = rp.PostId AND v.BountyAmount IS NOT NULL), 0), 'No Bounty') AS AverageBounty,
    CASE 
        WHEN tu.NetVotes IS NULL THEN 'No Votes'
        WHEN tu.NetVotes > 0 THEN 'Positive User'
        ELSE 'Negative User'
    END AS UserVotingStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistories th ON rp.PostId = th.PostId
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE 
    rp.Rank <= 3
ORDER BY 
    rp.Score DESC, 
    tu.NetVotes DESC, 
    th.HistoryRank ASC;
