WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
TopPostLinks AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        lt.Name AS LinkType,
        COUNT(*) AS LinkCount
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY 
        pl.PostId, pl.RelatedPostId, lt.Name
    HAVING 
        COUNT(*) > 1
),
FinalAnalytics AS (
    SELECT 
        up.Id AS UserId,
        up.DisplayName,
        COALESCE(up.Views, 0) AS ViewCount,
        COALESCE(up.UpVotes, 0) AS UpVoteCount,
        COALESCE(ub.BadgeCount, 0) AS TotalBadges,
        COALESCE(rp.PostCount, 0) AS TotalPosts,
        COALESCE(phd.HistoryCount, 0) AS TotalHistoryRecords,
        COALESCE(tpl.LinkCount, 0) AS TotalLinks,
        COALESCE(rp.TopPostTitle, 'No Posts') AS TopPostTitle
    FROM 
        Users up
    LEFT JOIN 
        UserBadgeCounts ub ON up.Id = ub.UserId
    LEFT JOIN 
        (SELECT 
            OwnerUserId, 
            COUNT(Id) AS PostCount,
            MAX(Title) FILTER (WHERE PostRank = 1) AS TopPostTitle
         FROM 
            RankedPosts 
         GROUP BY OwnerUserId) rp ON up.Id = rp.OwnerUserId
    LEFT JOIN 
        PostHistoryDetails phd ON up.Id = phd.PostId
    LEFT JOIN 
        TopPostLinks tpl ON up.Id = tpl.PostId
    WHERE 
        COALESCE(up.Views, 0) > 1000
    ORDER BY 
        TotalBadges DESC, UpVoteCount DESC
)
SELECT 
    fa.UserId,
    fa.DisplayName,
    fa.ViewCount,
    fa.UpVoteCount,
    fa.TotalBadges,
    fa.TotalPosts,
    fa.TotalHistoryRecords,
    fa.TotalLinks,
    fa.TopPostTitle
FROM 
    FinalAnalytics fa
WHERE 
    fa.UpVoteCount > (SELECT AVG(UpVotes) FROM Users)
    OR NOT EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = fa.UserId AND p.Score > 0)
ORDER BY 
    fa.UpVoteCount DESC, fa.ViewCount DESC;

