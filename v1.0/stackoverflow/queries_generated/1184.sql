WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
), PopularTags AS (
    SELECT 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.TotalBadges,
    ua.CommentCount,
    ua.PostCount,
    ua.TotalBounties,
    rp.Title AS RecentPost,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    pt.TagName,
    pt.TagCount
FROM 
    UserReputation up
JOIN 
    UserActivity ua ON up.UserId = ua.UserId
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.OwnerPostRank = 1
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (
        SELECT 
            DISTINCT UNNEST(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
        FROM 
            RankedPosts rp_inner
        WHERE 
            rp_inner.Id = rp.Id
    )
WHERE 
    up.Reputation > 1000
ORDER BY 
    up.Reputation DESC, 
    ua.CommentCount DESC
LIMIT 50;
