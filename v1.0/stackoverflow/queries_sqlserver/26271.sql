
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
        AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')  
),
TopTags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '>') AS TagsSplit
    WHERE 
        PostTypeId = 1
    GROUP BY 
        value
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
        TopTags tt ON tt.TagName IN (SELECT value FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags) - 2), '>'))
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
        Date >= DATEADD(YEAR, -1, '2024-10-01 12:34:56') 
    GROUP BY 
        UserId
) badgeSummary ON ps.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = badgeSummary.UserId)
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC;
