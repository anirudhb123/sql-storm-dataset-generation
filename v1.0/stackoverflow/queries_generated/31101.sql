WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Tags) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Tags) > 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ClosedDate,
        COUNT(ph.Id) AS CloseReasonCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 -- Post Closed
    WHERE 
        p.ClosedDate IS NOT NULL 
    GROUP BY 
        p.Id, p.Title, p.ClosedDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Owner,
    rp.CreationDate,
    rp.Score,
    pt.TagName,
    ub.BadgeCount,
    cp.CloseReasonCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.PostId IN (SELECT Unnest(string_to_array(rp.Tags, ',')))
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 3 -- Select top 3 posts per user
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
