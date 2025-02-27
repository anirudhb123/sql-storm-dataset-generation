WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVoteCount,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only consider questions
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.PostRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.ViewCount >= 1000  -- Filter posts with at least 1000 views
        AND rp.UpVoteCount - rp.DownVoteCount > 0  -- Only include posts with a net positive score
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    ARRAY_TO_STRING(STRING_TO_ARRAY(fp.Tags, '<>'), ', ') AS ProcessedTags,
    fp.ViewCount,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.PostRank
FROM 
    FilteredPosts fp
WHERE 
    fp.PostRank <= 100  -- Limit to top 100 recent posts
ORDER BY 
    fp.ViewCount DESC;  -- Order by view count in descending order
