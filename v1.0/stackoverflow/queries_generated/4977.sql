WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag(tagName)
    LEFT JOIN 
        Tags t ON tag.tagName = t.TagName
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.Id,
    rp.Title,
    rp.OwnerName,
    rp.Rank,
    rp.Score,
    rp.ViewCount,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(ub.GoldBadges, 0) AS UserGoldBadges,
    COALESCE(ub.SilverBadges, 0) AS UserSilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS UserBronzeBadges,
    COALESCE(pvs.UpVotes, 0) AS PostUpVotes,
    COALESCE(pvs.DownVotes, 0) AS PostDownVotes,
    COALESCE(pvs.TotalVotes, 0) AS PostTotalVotes,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No Views'
        WHEN rp.ViewCount > 1000 THEN 'Highly Viewed'
        WHEN rp.ViewCount BETWEEN 100 AND 1000 THEN 'Moderately Viewed'
        ELSE 'Low Views'
    END AS ViewCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostVoteStats pvs ON rp.Id = pvs.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
