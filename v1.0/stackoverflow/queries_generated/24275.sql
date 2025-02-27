WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS PostRank,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsList
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')))
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, pt.Name
), 
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN pht.Name IN ('Edit Title', 'Edit Body') THEN 1 END) AS TotalEdits
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, ph.UserId
)

SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.Score,
    CASE 
        WHEN uwb.TotalBadges IS NULL THEN 'No Badges'
        ELSE CONCAT(uwb.TotalBadges::text, ' Badges (', uwb.GoldBadges::text, ' Gold, ', uwb.SilverBadges::text, ' Silver, ', uwb.BronzeBadges::text, ' Bronze)')
    END AS BadgeSummary,
    phs.LastClosedDate,
    phs.TotalEdits,
    CASE 
        WHEN rp.PostRank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpvoteCount,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownvoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UsersWithBadges uwb ON uwb.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    PostHistorySummary phs ON phs.PostId = rp.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 100;
