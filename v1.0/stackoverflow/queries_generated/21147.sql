WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        b.Class,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId, b.Class
),
PostVoteHistory AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        pht.Name AS HistoryType,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, pht.Name
)
SELECT 
    p.PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    RANKD.RankByViews,
    RANKS.RankByScore,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(pvh.VoteCount, 0) AS TotalVotes,
    COALESCE(pvh.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvh.DownVotes, 0) AS TotalDownVotes,
    COALESCE(phd.HistoryCount, 0) AS TotalHistoryEntries,
    COUNT(DISTINCT pht.Id) AS UniqueHistoryTypes,
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    CASE 
        WHEN RANKD.RankByViews = 1 THEN 'Top Viewed'
        WHEN RANKS.RankByScore = 1 THEN 'Highest Scoring'
        ELSE NULL 
    END AS SpecialStatus
FROM 
    RankedPosts RANKD
LEFT JOIN 
    UserBadges ub ON RANKD.PostId = ub.UserId
LEFT JOIN 
    PostVoteHistory pvh ON RANKD.PostId = pvh.PostId
LEFT JOIN 
    PostHistoryDetails phd ON RANKD.PostId = phd.PostId
LEFT JOIN 
    PostHistory ph ON ph.PostId = RANKD.PostId
GROUP BY 
    p.PostId, RANKD.RankByViews, RANKS.RankByScore, ub.BadgeCount, ub.BadgeNames, 
    pvh.VoteCount, pvh.UpVotes, pvh.DownVotes, phd.HistoryCount
ORDER BY 
    RANKD.RankByViews, DESC
LIMIT 100 OFFSET 0;
