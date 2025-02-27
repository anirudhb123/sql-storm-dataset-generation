WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2)  -- Only Questions and Answers
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(b.Class) AS TotalBadgeClass -- Assuming this represents a measure of reputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000  -- Filter users with significant reputation
    GROUP BY 
        u.Id, u.Reputation
),
AggregateVotes AS (
    SELECT
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month'  -- Recent posts
    GROUP BY 
        p.Id
),
PostHistoryAnalytics AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        STRING_AGG(DISTINCT CAST(ph.Comment AS VARCHAR), ', ') AS CloseReasons
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Recent changes
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    u.Reputation,
    ur.PostCount,
    av.UpVotes,
    av.DownVotes,
    av.TotalVotes,
    pha.CloseCount,
    pha.ReopenCount,
    pha.CloseReasons
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    AggregateVotes av ON rp.PostId = av.PostId
LEFT JOIN 
    PostHistoryAnalytics pha ON rp.PostId = pha.PostId
WHERE 
    rp.UserPostRank <= 3  -- Top 3 posts per user
    AND (rp.Score > 5 OR av.UpVotes > av.DownVotes)  -- Popular or upvoted posts
ORDER BY 
    u.Reputation DESC, rp.Score DESC, rp.CreationDate DESC
LIMIT 100;

-- Note: The query aggregates various dimensions of post and user data, 
-- including performance metrics, voting behavior, and history tracking.
