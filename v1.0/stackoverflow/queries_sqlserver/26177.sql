
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.Body, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags, u.DisplayName
),
TagStatistics AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        FilteredPosts
    CROSS APPLY STRING_SPLIT(TRIM(BOTH '<>' FROM Tags), '><')
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    fp.Upvotes,
    fp.Downvotes,
    tt.TagName,
    tt.TagCount
FROM 
    FilteredPosts fp
JOIN 
    TopTags tt ON tt.TagName = value
WHERE 
    tt.TagRank <= 5 
ORDER BY 
    fp.ViewCount DESC, 
    fp.Score DESC;
