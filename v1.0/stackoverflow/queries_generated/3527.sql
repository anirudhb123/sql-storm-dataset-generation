WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.ViewCount > 10
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes,
        (SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3)) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryRemarks AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        ph.CreationDate,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RemarkRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Consider only closed or reopened
),
AggregatedVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalPosts,
    up.TotalUpvotes,
    up.TotalDownvotes,
    up.NetVotes,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ph.Comment AS LatestRemark,
    ph.CreationDate AS RemarkDate,
    av.TotalVotes
FROM 
    UserStatistics up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.PostId
LEFT JOIN 
    PostHistoryRemarks ph ON rp.PostId = ph.PostId AND ph.RemarkRank = 1
LEFT JOIN 
    AggregatedVotes av ON rp.PostId = av.PostId
WHERE 
    up.Reputation > 1000
    AND (av.TotalVotes IS NULL OR av.TotalVotes > 5)
    AND rp.PostRank <= 3
ORDER BY 
    up.Reputation DESC, rp.Score DESC;
