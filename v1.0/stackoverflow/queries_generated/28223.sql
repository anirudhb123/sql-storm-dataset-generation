WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(p.Tags, ',') tag_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(both '<>' FROM tag_array)
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),
TopPostContributors AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(rp.PostId) AS PostCount,
        MAX(rp.Score) AS MaxScore,
        MAX(rb.BadgeCount) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges rb ON rp.OwnerUserId = rb.UserId
    GROUP BY 
        rp.OwnerDisplayName
)
SELECT 
    t.OwnerDisplayName,
    t.PostCount,
    t.MaxScore,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(b.BadgeNames, 'No badges') AS BadgeNames
FROM 
    TopPostContributors t
LEFT JOIN 
    UserBadges b ON t.OwnerDisplayName = b.UserId
ORDER BY 
    t.PostCount DESC, t.MaxScore DESC
LIMIT 10;
