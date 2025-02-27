
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TopTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        tt.TagName,
        tt.TagCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    JOIN 
        TopTags tt ON FIND_IN_SET(tt.TagName, SUBSTRING(rp.Tags, 2, CHAR_LENGTH(rp.Tags) - 2))
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.ViewCount, rp.Score, rp.OwnerDisplayName, tt.TagName, tt.TagCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Body,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.OwnerDisplayName,
    ps.TagName,
    ps.TagCount,
    ps.CommentCount,
    COALESCE(badgeSummary.BadgeCount, 0) AS BadgeCount
FROM 
    PostStatistics ps
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
    FROM 
        Badges 
    WHERE 
        Date >= NOW() - INTERVAL 1 YEAR 
    GROUP BY 
        UserId
) badgeSummary ON ps.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = badgeSummary.UserId)
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC;
