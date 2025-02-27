WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(p.Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    p.Title,
    rp.Score,
    rp.ViewCount,
    rb.GoldBadges,
    rb.SilverBadges,
    rb.BronzeBadges,
    pt.TagName,
    pt.TagCount
FROM 
    Users u
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    UserBadges rb ON u.Id = rb.UserId
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (SELECT UNNEST(string_to_array(rp.Title, ' ')))
WHERE 
    rp.Rank <= 5 AND 
    (rb.GoldBadges IS NOT NULL OR rb.SilverBadges IS NOT NULL OR rb.BronzeBadges IS NOT NULL)
ORDER BY 
    rp.Score DESC, pt.TagCount DESC;
