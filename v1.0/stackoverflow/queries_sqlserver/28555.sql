
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.CreationDate, 
        p.OwnerUserId, 
        u.DisplayName AS OwnerDisplayName,
        p.Tags, 
        p.Score,
        p.ViewCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
TagStats AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        RecentPosts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount
    FROM 
        TagStats
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
Benchmark AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        tt.TagName,
        rp.Score,
        rp.ViewCount, 
        rp.CommentCount, 
        rp.UpVoteCount, 
        rp.DownVoteCount
    FROM 
        RecentPosts rp
    JOIN 
        TopTags tt ON rp.Tags LIKE '%' + tt.TagName + '%'
)
SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    OwnerDisplayName,
    TagName,
    Score,
    ViewCount,
    CommentCount,
    UpVoteCount,
    DownVoteCount
FROM 
    Benchmark
ORDER BY 
    Score DESC, ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
