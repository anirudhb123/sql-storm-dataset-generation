WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
TagUsage AS (
    SELECT 
        Tag,
        COUNT(*) AS UsageCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 5
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        ARRAY_AGG(b.Name) AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    tb.Tag AS PopularTag,
    ub.BadgeNames,
    ub.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TagUsage tb ON tb.Tag LIKE '%' || (SELECT Tag FROM TagUsage ORDER BY UsageCount DESC LIMIT 1) || '%'
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.CommentCount DESC NULLS LAST, 
    rp.UpVotes - rp.DownVotes DESC;

-- Additionally, a curious case of NULL logic
SELECT 
    p.Title,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN p.OwnerUserId IS NULL THEN 'User Deleted'
        WHEN b.BadgeCount IS NULL THEN 'No Badges'
        ELSE 'Has Badges'
    END AS BadgeStatus 
FROM 
    Posts p
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) b ON p.OwnerUserId = b.UserId
WHERE 
    p.CreationDate < NOW() - INTERVAL '30 days'
ORDER BY 
    BadgeCount DESC, 
    p.Title;
