
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
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
TagStats AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        RecentPosts,
        LATERAL SPLIT_TO_TABLE(Tags, '><') AS value
    GROUP BY 
        TRIM(value)
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount
    FROM 
        TagStats
    ORDER BY 
        PostCount DESC
    LIMIT 10
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
        TopTags tt ON POSITION(tt.TagName IN rp.Tags) > 0
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
LIMIT 20;
