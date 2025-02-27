
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
        TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        FilteredPosts f,
        (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6) t, (SELECT @row := 0) r) n
    WHERE 
        n.n <= LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')) + 1
    GROUP BY 
        TagName
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
    TopTags tt ON tt.TagName IN (TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, '><', n.n), '><', -1)))
WHERE 
    tt.TagRank <= 5 
ORDER BY 
    fp.ViewCount DESC, 
    fp.Score DESC;
