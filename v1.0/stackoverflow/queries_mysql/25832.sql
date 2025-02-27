
WITH TagsArray AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
),
TaggedPosts AS (
    SELECT 
        t.Tag,
        COUNT(*) AS PostCount
    FROM 
        TagsArray t
    GROUP BY 
        t.Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM 
        TaggedPosts, (SELECT @rank := 0) r
    WHERE 
        PostCount > 10
    ORDER BY 
        PostCount DESC
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        pp.Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        TopTags pp ON EXISTS (SELECT 1 FROM TagsArray ta WHERE ta.PostId = p.Id AND ta.Tag = pp.Tag)
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY AND 
        p.PostTypeId = 1
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerName,
    tt.Tag,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount
FROM 
    RecentPosts rp
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
LEFT JOIN 
    Votes v ON rp.PostId = v.PostId
LEFT JOIN 
    TopTags tt ON rp.Rank = tt.Rank
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.OwnerName, tt.Tag
ORDER BY 
    rp.CreationDate DESC, VoteCount DESC
LIMIT 50;
