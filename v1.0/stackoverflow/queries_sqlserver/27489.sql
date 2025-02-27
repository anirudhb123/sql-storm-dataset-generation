
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        LEN(string_split(substring(p.Tags, 2, LEN(p.Tags) - 2), '>')) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        u.Reputation AS UserReputation,
        u.DisplayName AS UserDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '30 days' 
),
TopTags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagUsage
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(substring(p.Tags, 2, LEN(p.Tags) - 2), '>') 
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '30 days'
    GROUP BY 
        value
    ORDER BY 
        TagUsage DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT c.UserDisplayName, ', ') AS CommentAuthors
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.Body,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.TagCount,
    r.UserReputation,
    r.UserDisplayName,
    pc.CommentCount,
    pc.CommentAuthors,
    tt.TagName AS PopularTag,
    tt.TagUsage AS TagUsageCount
FROM 
    RankedPosts r
LEFT JOIN 
    PostComments pc ON r.PostId = pc.PostId
LEFT JOIN 
    TopTags tt ON tt.TagName IN (SELECT value FROM STRING_SPLIT(substring(r.Tags, 2, LEN(r.Tags) - 2), '>'))
WHERE 
    r.PostRank = 1 
ORDER BY 
    r.Score DESC, r.ViewCount DESC;
