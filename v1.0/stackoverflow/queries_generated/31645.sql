WITH RecursivePostHistory AS (
    -- Recursive CTE to get the full post history along with type counts
    SELECT 
        h.PostId,
        h.PostHistoryTypeId,
        COUNT(*) OVER (PARTITION BY h.PostId) AS TotalHistory,
        1 AS Level
    FROM PostHistory h
    WHERE h.PostHistoryTypeId IN (1, 2, 4, 10) -- Considering only relevant history types for analysis
    UNION ALL
    SELECT 
        h.PostId,
        h.PostHistoryTypeId,
        COUNT(*) OVER (PARTITION BY h.PostId) AS TotalHistory,
        Level + 1
    FROM PostHistory h
    JOIN RecursivePostHistory r ON h.PostId = r.PostId
    WHERE h.PostHistoryTypeId IN (1, 2, 4, 10) -- Continue for relevant types
),
PostVoteSummary AS (
    -- Summarizing votes for each post
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
UserBadgeCounts AS (
    -- Getting badge counts per user
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostAnalytics AS (
    -- Final combined selection for posts with their analytics
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        ph.TotalHistory,
        pvs.UpVotes,
        pvs.DownVotes,
        ubc.UserId,
        ubc.GoldBadges,
        ubc.SilverBadges,
        ubc.BronzeBadges,
        -- Finding the most recent activity
        COALESCE(ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC), NULL) AS RecentActivityRank
    FROM Posts p
    LEFT JOIN RecursivePostHistory ph ON p.Id = ph.PostId
    LEFT JOIN PostVoteSummary pvs ON p.Id = pvs.PostId
    LEFT JOIN UserBadgeCounts ubc ON p.OwnerUserId = ubc.UserId
    WHERE p.AcceptedAnswerId IS NOT NULL
)
-- The final output selecting relevant details from PostAnalytics
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.TotalHistory,
    pa.UpVotes,
    pa.DownVotes,
    pa.GoldBadges,
    pa.SilverBadges,
    pa.BronzeBadges,
    CASE 
        WHEN pa.RecentActivityRank IS NOT NULL THEN 'Active'
        ELSE 'Inactive' 
    END AS ActivityStatus
FROM PostAnalytics pa
ORDER BY pa.TotalHistory DESC, pa.UpVotes DESC;
