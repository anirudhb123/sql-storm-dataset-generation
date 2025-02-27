WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Considering only Upvotes and Downvotes
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(p.Tags, ',') AS tag_array ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag_array
    WHERE 
        p.PostTypeId = 1 -- Focusing on Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, u.DisplayName
),
PostBenchmark AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.CommentCount,
        rp.VoteCount,
        rp.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY rp.OwnerDisplayName ORDER BY rp.Score DESC, rp.CommentCount DESC) AS OwnerRank
    FROM 
        RankedPosts rp
)
SELECT 
    pb.PostId,
    pb.Title,
    pb.OwnerDisplayName,
    pb.Score,
    pb.CommentCount,
    pb.VoteCount,
    pb.CreationDate,
    pb.OwnerRank,
    pht.Name AS PostHistoryTypeName,
    ph.CreationDate AS PostHistoryDate,
    ph.UserDisplayName AS EditorDisplayName,
    ph.Comment AS EditComment
FROM 
    PostBenchmark pb
LEFT JOIN 
    PostHistory ph ON pb.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    pht.Name IN ('Edit Body', 'Edit Title') -- Filtering for relevant history types
ORDER BY 
    pb.Score DESC, pb.CommentCount DESC;
