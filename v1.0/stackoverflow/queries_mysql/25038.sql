
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.Score, p.OwnerUserId
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
),

TagStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.tag, '>', n.n), '<', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts t
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON 
        CHAR_LENGTH(t.Tags) - CHAR_LENGTH(REPLACE(t.Tags, '>', '')) >= n.n
    GROUP BY 
        TagName
),

TopTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        RANK() OVER (ORDER BY ts.PostCount DESC) AS Rank
    FROM 
        TagStats ts
)

SELECT 
    tt.TagName,
    tt.PostCount,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fp.AnswerCount
FROM 
    TopTags tt
JOIN 
    FilteredPosts fp ON fp.Tags LIKE CONCAT('%', tt.TagName, '%')
WHERE 
    tt.Rank <= 10
ORDER BY 
    tt.PostCount DESC, 
    fp.Score DESC;
