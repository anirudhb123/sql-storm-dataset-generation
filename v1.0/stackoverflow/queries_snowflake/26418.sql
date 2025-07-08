
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
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),

TagCounts AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS JOIN 
        LATERAL SPLIT_TO_TABLE(Tags, '><') AS value
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),

TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    LIMIT 10
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
    (SELECT DISTINCT p.Id, TRIM(value) AS TagName
     FROM Posts p 
     CROSS JOIN LATERAL SPLIT_TO_TABLE(p.Tags, '><') AS value 
     WHERE p.Tags IS NOT NULL) AS TagLinks 
ON 
    ps.PostId = TagLinks.Id
JOIN 
    TopTags tt ON TagLinks.TagName = tt.TagName
ORDER BY 
    ps.CommentCount DESC, ps.UpVoteCount DESC
LIMIT 100;
