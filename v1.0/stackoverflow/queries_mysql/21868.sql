mysql
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RN,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS CreationRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(v.Id) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistoryWithVoteCounts AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.Name SEPARATOR ', ') AS HistoryTypeNames
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes t ON ph.PostHistoryTypeId = t.Id
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        us.UserId,
        us.BadgeCount,
        us.TotalReputation,
        us.VoteCount,
        COALESCE(phwv.VoteCount, 0) AS PostVoteCount
    FROM 
        RankedPosts rp
    JOIN 
        UserScores us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        PostHistoryWithVoteCounts phwv ON rp.PostId = phwv.PostId
    WHERE 
        rp.RN <= 10
)
SELECT 
    fp.Title,
    fp.UserId,
    fp.BadgeCount,
    fp.TotalReputation,
    fp.VoteCount,
    fp.PostVoteCount,
    CASE 
        WHEN fp.PostVoteCount IS NULL THEN 'No Votes'
        WHEN fp.PostVoteCount > 5 THEN 'Highly Engaged'
        ELSE 'Moderately Engaged' 
    END AS EngagementLevel,
    (CASE 
        WHEN fp.BadgeCount > 10 THEN 'Expert'
        WHEN fp.BadgeCount BETWEEN 5 AND 10 THEN 'Intermediate'
        ELSE 'Novice' 
    END) AS UserExpertise
FROM 
    FilteredPosts fp
ORDER BY 
    fp.TotalReputation DESC, 
    fp.PostVoteCount DESC
LIMIT 20 OFFSET 0
;