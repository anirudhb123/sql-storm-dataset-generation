WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Active'
        END AS Status,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
    WHERE 
        p.ViewCount > 100
),
TagCounts AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        TagName
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        tc.TagName,
        uwb.DisplayName,
        uwb.BadgeCount,
        uwb.BadgeNames
    FROM 
        RankedPosts rp
    JOIN 
        UsersWithBadges uwb ON rp.OwnerUserId = uwb.UserId
    JOIN 
        TagCounts tc ON tc.TagName IN (SELECT UNNEST(STRING_TO_ARRAY(rp.Tags, '><')))
    WHERE 
        rp.rn = 1
)
SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    Score,
    ViewCount,
    TagName,
    DisplayName,
    BadgeCount,
    BadgeNames
FROM 
    TopPosts
ORDER BY 
    ViewCount DESC, Score DESC
LIMIT 10;
