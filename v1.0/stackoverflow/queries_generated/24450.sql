WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.ViewCount IS NOT NULL
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
HighScorers AS (
    SELECT 
        p.OwnerUserId,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
    HAVING 
        COUNT(p.Id) > 10
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(u.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(u.BadgeNames, 'None') AS UserBadges,
    hs.TotalScore AS UserTotalScore,
    hs.PostCount AS UserPostCount,
    pvs.UpVotes,
    pvs.DownVotes,
    ph.CloseVotes,
    ph.HistoryTypes
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges u ON u.UserId = rp.OwnerUserId
LEFT JOIN 
    HighScorers hs ON hs.OwnerUserId = rp.OwnerUserId
LEFT JOIN 
    PostVoteStats pvs ON pvs.PostId = rp.PostId
LEFT JOIN 
    PostHistoryDetails ph ON ph.PostId = rp.PostId
WHERE 
    rp.Rank <= 10
    AND (rp.Score IS NOT NULL OR rp.ViewCount >= 100)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;

