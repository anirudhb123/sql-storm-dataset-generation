
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(v.Id) DESC) AS Rank,
        p.CreationDate,
        p.LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate, p.LastActivityDate
),

RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    WHERE 
        b.Date >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 1 MONTH
    GROUP BY 
        b.UserId
),

TagStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(p.Id) AS PostCount
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
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.VoteCount,
    rb.BadgeCount,
    ts.PostCount AS TagUsageCount,
    rp.LastActivityDate
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentBadges rb ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = rb.UserId)
LEFT JOIN 
    TagStats ts ON FIND_IN_SET(ts.Tag, REPLACE(REPLACE(rp.Tags, '><', ','), '<', ''), '>',''))
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.VoteCount DESC, rp.LastActivityDate DESC;
