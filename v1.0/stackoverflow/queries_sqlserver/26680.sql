
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Author,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST(DATEADD(DAY, -30, '2024-10-01') AS DATE)
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.Tags
),
ProcessedTags AS (
    SELECT 
        PostId,
        value AS Tag
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(Tags, ',')
),
TagCounts AS (
    SELECT 
        Tag, 
        COUNT(DISTINCT PostId) AS PostCount
    FROM 
        ProcessedTags
    WHERE 
        Tag IS NOT NULL AND Tag <> ''
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount > 1
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Author,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        (SELECT COUNT(*) FROM TopTags tt WHERE tt.Tag IN (SELECT value FROM STRING_SPLIT(rp.Tags, ','))) AS AssociatedTagsCount
    FROM 
        RankedPosts rp
)

SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    ViewCount,
    Author,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    AssociatedTagsCount
FROM 
    FinalResults
WHERE 
    ViewCount > 10 OR CommentCount > 5
ORDER BY 
    UpvoteCount DESC, ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
