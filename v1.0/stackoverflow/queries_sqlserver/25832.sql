
WITH TagsArray AS (
    SELECT 
        p.Id AS PostId,
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS Tag
    FROM 
        Posts p
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
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TaggedPosts
    WHERE 
        PostCount > 10
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
        TopTags pp ON EXISTS (SELECT 1 FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS a WHERE a.value = pp.Tag)
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56') AND 
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
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
