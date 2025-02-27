WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        COUNT(a.Id) AS AnswerCount,
        MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS IsUpvoted,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.UserId = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Tags
),

PostTags AS (
    SELECT 
        p.PostId,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        Posts p
    CROSS APPLY 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>><<') AS t
    GROUP BY 
        p.PostId
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
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Tags AS RawTags,
    pt.TagList,
    rp.AnswerCount,
    ub.BadgeCount,
    CASE 
        WHEN ub.HighestBadgeClass = 1 THEN 'Gold'
        WHEN ub.HighestBadgeClass = 2 THEN 'Silver'
        WHEN ub.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS HighestBadge,
    rp.IsUpvoted,
    rp.UserRank
FROM 
    RankedPosts rp
JOIN 
    PostTags pt ON rp.PostId = pt.PostId
JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
ORDER BY 
    rp.CreationDate DESC, rp.UserRank;
