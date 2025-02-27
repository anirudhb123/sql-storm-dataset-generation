
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
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
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
        b.Date >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 month'
    GROUP BY 
        b.UserId
),

TagStats AS (
    SELECT 
        value AS Tag,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    CROSS APPLY 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS TagValue
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        value
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
    TagStats ts ON CHARINDEX(ts.Tag, rp.Tags) > 0
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.VoteCount DESC, rp.LastActivityDate DESC;
