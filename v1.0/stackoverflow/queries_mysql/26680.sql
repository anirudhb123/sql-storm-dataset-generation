
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
        p.CreationDate >= CURDATE() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName, p.Tags
),
ProcessedTags AS (
    SELECT 
        PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS Tag
    FROM 
        RankedPosts
    INNER JOIN (
        SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION
        SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
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
        (SELECT COUNT(*) FROM TopTags tt WHERE tt.Tag = SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, ',', numbers.n), ',', -1)) AS AssociatedTagsCount
    FROM 
        RankedPosts rp
    CROSS JOIN (
        SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION
        SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) numbers
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
LIMIT 50;
