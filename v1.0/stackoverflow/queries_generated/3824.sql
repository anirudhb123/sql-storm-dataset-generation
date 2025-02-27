WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rnk
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
RecentVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        v.PostId
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.Score,
    ub.BadgeCount,
    ub.HighestBadgeClass,
    COALESCE(rv.UpVotes, 0) AS UpVotes,
    COALESCE(rv.DownVotes, 0) AS DownVotes
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    RecentVotes rv ON rp.Id = rv.PostId
WHERE 
    rp.rnk = 1
ORDER BY 
    rp.Score DESC, 
    ub.BadgeCount DESC
LIMIT 10;

WITH TagCount AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags
    JOIN 
        Posts p ON Tags.Id = ANY (STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')::int[])
    GROUP BY 
        Tags.TagName
)
SELECT 
    t.TagName,
    tc.PostCount
FROM 
    Tags t
RIGHT JOIN 
    TagCount tc ON t.TagName = tc.TagName
WHERE 
    tc.PostCount > 5
ORDER BY 
    tc.PostCount DESC
LIMIT 5;
