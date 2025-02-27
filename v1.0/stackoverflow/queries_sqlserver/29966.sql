
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.AcceptedAnswerId IS NOT NULL 
),
TagStatistics AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS TagList
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        value
),
TopBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') WITHIN GROUP (ORDER BY b.Name) AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
)
SELECT 
    rp.PostId,
    rp.Title AS PostTitle,
    rp.Body AS PostBody,
    rp.CreationDate AS PostCreationDate,
    pu.DisplayName AS AuthorDisplayName,
    pu.Reputation AS AuthorReputation,
    ts.Tag AS PopularTag,
    ts.TagCount AS TagUsageCount,
    tb.BadgeCount AS AuthorGoldBadgeCount,
    tb.BadgeNames AS AuthorGoldBadges
FROM 
    RankedPosts rp
JOIN 
    Users pu ON rp.OwnerUserId = pu.Id
LEFT JOIN 
    TagStatistics ts ON ts.Tag IN (
        SELECT value
        FROM STRING_SPLIT(SUBSTRING((SELECT Tags FROM Posts p WHERE p.Id = rp.PostId), 2, LEN((SELECT Tags FROM Posts p WHERE p.Id = rp.PostId)) - 2), '><')
    )
LEFT JOIN 
    TopBadges tb ON tb.UserId = rp.OwnerUserId
WHERE 
    rp.PostRank = 1 
ORDER BY 
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
