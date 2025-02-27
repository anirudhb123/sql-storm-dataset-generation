
WITH TagCounts AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) OVER (PARTITION BY SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagOccurrence
    FROM 
        Posts p
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
),
MostPopularTags AS (
    SELECT 
        tc.TagName,
        COUNT(DISTINCT tc.PostId) AS PostCount,
        SUM(tc.TagOccurrence) AS TotalOccurrences
    FROM 
        TagCounts tc
    GROUP BY 
        tc.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS Author,
        COALESCE(b.BadgeCount, 0) AS AuthorBadgeCount
    FROM 
        Posts p 
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId 
    WHERE 
        p.PostTypeId = 1
)
SELECT 
    p.Title,
    p.ViewCount,
    p.CreationDate,
    p.Author,
    t.TagName,
    t.PostCount,
    t.TotalOccurrences,
    p.AuthorBadgeCount
FROM 
    PostDetails p
JOIN 
    MostPopularTags t ON FIND_IN_SET(t.TagName, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) > 0
ORDER BY 
    t.TotalOccurrences DESC, p.ViewCount DESC;
