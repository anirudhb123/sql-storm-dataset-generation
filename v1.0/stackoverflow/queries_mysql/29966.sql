
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        Tag
),
TopBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name ORDER BY b.Name SEPARATOR ', ') AS BadgeNames
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
        SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)
        FROM Posts p INNER JOIN (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        WHERE p.Id = rp.PostId
    )
LEFT JOIN 
    TopBadges tb ON tb.UserId = rp.OwnerUserId
WHERE 
    rp.PostRank = 1 
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
