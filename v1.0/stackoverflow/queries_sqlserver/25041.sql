
WITH TagCounts AS (
    SELECT 
        p.Id AS PostId,
        value AS TagName,
        COUNT(*) OVER (PARTITION BY value) AS TagOccurrence
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS value
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
    MostPopularTags t ON t.TagName IN (SELECT value FROM STRING_SPLIT(SUBSTRING(p.Title, 2, LEN(p.Title) - 2), '><'))
ORDER BY 
    t.TotalOccurrences DESC, p.ViewCount DESC;
