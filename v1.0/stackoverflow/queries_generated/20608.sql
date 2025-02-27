WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotesReceived, -- Upvotes received
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotesReceived -- Downvotes received
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.Reputation,
    up.UpVotesReceived,
    up.DownVotesReceived,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(phs.HistoryCount, 0) AS PostHistoryCount,
    phs.HistoryTypes,
    CASE 
        WHEN up.Reputation IS NULL THEN 'No Reputation'
        WHEN up.Reputation >= 1000 THEN 'High Reputation'
        ELSE 'Moderate Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN rp.UserPostRank = 1 AND phs.HistoryCount = 0 THEN 'First Post, No Edits'
        WHEN rp.UserPostRank > 1 THEN 'Subsequent Post'
        ELSE 'Unique or Single Post'
    END AS PostTypeDescription
FROM 
    UserReputation up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    up.Reputation > 100
ORDER BY 
    up.Reputation DESC, 
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

-- This query aims to analyze users with significant reputation,
-- correlating their posted questions and the historical edits,
-- while also categorizing both user reputation and post types.
