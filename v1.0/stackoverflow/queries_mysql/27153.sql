
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
TagStatistics AS (
    SELECT 
        TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
         UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        @rownum := @rownum + 1 AS Rank
    FROM 
        TagStatistics, (SELECT @rownum := 0) r
    WHERE 
        PostCount > 1 
    ORDER BY 
        PostCount DESC
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerName,
    pd.CreationDate,
    pd.Upvotes,
    pd.Downvotes,
    pd.CommentCount,
    pd.BadgeCount,
    tt.TagName AS MostPopularTag,
    tt.PostCount AS TagUsageCount
FROM 
    PostDetails pd
LEFT JOIN 
    TopTags tt ON pd.Tags LIKE CONCAT('%', tt.TagName, '%')
WHERE 
    pd.CreationDate >= NOW() - INTERVAL 1 YEAR
ORDER BY 
    pd.Upvotes DESC, pd.CommentCount DESC, pd.CreationDate DESC;
