WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),

TopPosts AS (
    SELECT 
        rp.*,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotesCount,  -- Upvotes only
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotesCount  -- Downvotes only
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1  -- Get the latest revision of each post
),

TagStatistics AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, ','))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only questions
    GROUP BY 
        TagName
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.UpVotesCount,
    tp.DownVotesCount,
    ts.TagName,
    ts.PostCount
FROM 
    TopPosts tp
JOIN 
    TagStatistics ts ON tp.Tags LIKE '%' || ts.TagName || '%'  -- Join on tags
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC
LIMIT 10;  -- Top 10 posts by score and view count
