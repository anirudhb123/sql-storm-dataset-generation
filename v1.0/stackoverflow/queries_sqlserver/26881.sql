
WITH TagSplit AS (
    SELECT 
        p.Id AS PostId,
        TRIM(value) AS TagName
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') 
),
TagStatistics AS (
    SELECT 
        ts.TagName,
        COUNT(DISTINCT ts.PostId) AS PostCount,
        AVG(u.Reputation) AS AverageReputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        TagSplit ts
    JOIN 
        Posts p ON ts.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        ts.TagName
),
MostLinkedTags AS (
    SELECT 
        tl.TagName,
        COUNT(pl.RelatedPostId) AS LinkCount
    FROM 
        TagSplit tl
    JOIN 
        PostLinks pl ON tl.PostId = pl.PostId
    GROUP BY 
        tl.TagName
),
FinalStats AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.AverageReputation,
        ts.BadgeCount,
        mt.LinkCount
    FROM 
        TagStatistics ts
    LEFT JOIN 
        MostLinkedTags mt ON ts.TagName = mt.TagName
)
SELECT 
    TagName,
    PostCount,
    AverageReputation,
    COALESCE(BadgeCount, 0) AS BadgeCount,
    COALESCE(LinkCount, 0) AS LinkCount
FROM 
    FinalStats
ORDER BY 
    PostCount DESC, 
    AverageReputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
