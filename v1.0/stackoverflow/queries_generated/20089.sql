WITH PostVoteAnalytics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserAnalytics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate < CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id
),
PostHistoryMetrics AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        STRING_AGG(DISTINCT CONCAT(ph.UserDisplayName, ': ', ph.Comment), '; ') AS CloseReasons
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
),
CombinedAnalytics AS (
    SELECT 
        pa.PostId,
        ua.UserId,
        ua.DisplayName AS UserDisplayName,
        pa.UpVotes,
        pa.DownVotes,
        pa.TotalBounty,
        ph.CloseReopenCount,
        ph.CloseReasons
    FROM 
        PostVoteAnalytics pa
    JOIN 
        Posts p ON pa.PostId = p.Id
    JOIN 
        UserAnalytics ua ON p.OwnerUserId = ua.UserId
    LEFT JOIN 
        PostHistoryMetrics ph ON pa.PostId = ph.PostId
)
SELECT 
    ca.*,
    CASE 
        WHEN ca.UpVotes IS NULL THEN 'No votes yet'
        ELSE 'Votes received'
    END AS VoteStatus,
    CASE 
        WHEN ca.TotalBounty > 0 THEN 'Bounty awarded'
        ELSE 'No bounties'
    END AS BountyStatus
FROM 
    CombinedAnalytics ca
WHERE 
    ca.CloseReopenCount > 0
ORDER BY 
    ca.UserRank, ca.UpVotes DESC, ca.DownVotes ASC;
