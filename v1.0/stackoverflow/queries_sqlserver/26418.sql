
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount 
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56') 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),

TagCounts AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, '><') 
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        value
),

TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Body,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    tt.TagName,
    tt.PostCount AS AssociatedPostCount
FROM 
    PostStats ps
JOIN 
    (SELECT DISTINCT p.Id, value AS TagName
     FROM Posts p CROSS APPLY STRING_SPLIT(p.Tags, '><') 
     WHERE p.Tags IS NOT NULL) AS TagLinks 
ON 
    ps.PostId = TagLinks.Id
JOIN 
    (SELECT TOP 10 TagName, PostCount FROM TopTags ORDER BY PostCount DESC) tt 
ON 
    TagLinks.TagName = tt.TagName
ORDER BY 
    ps.CommentCount DESC, ps.UpVoteCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
