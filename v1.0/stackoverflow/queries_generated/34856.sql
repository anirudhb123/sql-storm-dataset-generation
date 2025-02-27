WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        LastAccessDate,
        DisplayName,
        Location
    FROM 
        Users
    WHERE 
        Reputation >= 1000  -- Start with high-reputation users
    UNION ALL
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.DisplayName,
        u.Location
    FROM 
        Users u
    JOIN 
        UserReputation ur ON u.Reputation < ur.Reputation
    WHERE 
        ur.Reputation - u.Reputation <= 500  -- Find users within 500 reputation
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'  -- Posts from the last 30 days
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
ClosedPostSummary AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Only consider posts that were closed
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    pvs.UpVotes,
    pvs.DownVotes,
    cps.FirstClosedDate,
    cps.LastClosedDate
FROM 
    UserReputation up
JOIN 
    RecentPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    ClosedPostSummary cps ON rp.PostId = cps.PostId
WHERE 
    rp.rn = 1  -- Only get the most recent post for each PostType
ORDER BY 
    up.Reputation DESC, 
    rp.CreationDate DESC
LIMIT 100;  -- Limit the output for performance
