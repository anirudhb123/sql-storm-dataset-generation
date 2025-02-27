WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UpVoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 2  -- Upvotes
    LEFT JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag_splitted ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag_splitted
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'  -- Filter recent posts
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosureDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Closed posts
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.Tags,
    cp.ClosureDate,
    cp.CloseReason
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId
WHERE 
    rp.PostRank <= 5  -- Top 5 recent posts of each type
ORDER BY 
    rp.CreationDate DESC;
