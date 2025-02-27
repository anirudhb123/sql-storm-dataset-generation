WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadgeCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadgeCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadgeCount,
        SUM(CASE WHEN b.Class IN (1, 2, 3) THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT pht.Name) AS HistoryTypes,
        MIN(ph.CreationDate) AS FirstActivityDate,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    up.Id AS UserId,
    u.DisplayName,
    up.PostId,
    up.Title,
    up.CreationDate,
    up.Score,
    up.CommentCount,
    ubc.GoldBadgeCount,
    ubc.SilverBadgeCount,
    ubc.BronzeBadgeCount,
    pvs.UpVotes,
    pvs.DownVotes,
    phs.HistoryTypes,
    phs.FirstActivityDate,
    phs.LastActivityDate,
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = up.OwnerUserId AND Score > up.Score) AS LesserScoredPosts
FROM 
    RankedPosts up
JOIN 
    Users u ON u.Id = up.OwnerUserId
LEFT JOIN 
    UserBadgeCounts ubc ON ubc.UserId = u.Id
LEFT JOIN 
    PostVoteSummary pvs ON pvs.PostId = up.PostId
LEFT JOIN 
    PostHistorySummary phs ON phs.PostId = up.PostId
WHERE 
    up.UserPostRank <= 5
    AND up.Score IS NOT NULL
    AND (EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = up.PostId AND v.UserId IS NULL) 
         OR phs.LastActivityDate > '2023-01-01 00:00:00')
ORDER BY 
    up.Score DESC, up.CreationDate DESC;
