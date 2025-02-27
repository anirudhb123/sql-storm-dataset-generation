WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        COALESCE(pc.ClosedPostCount, 0) AS ClosedPostCount,
        COALESCE(vc.UpvoteCount, 0) AS UpvoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            postId,
            COUNT(*) AS ClosedPostCount
        FROM 
            PostHistory ph
        WHERE 
            ph.PostHistoryTypeId = 10
        GROUP BY 
            postId
    ) pc ON rp.PostId = pc.PostId
    LEFT JOIN (
        SELECT 
            postId,
            COUNT(*) AS UpvoteCount
        FROM 
            Votes v
        WHERE 
            v.VoteTypeId = 2
        GROUP BY 
            postId
    ) vc ON rp.PostId = vc.PostId
    WHERE 
        rp.rn = 1
)
SELECT 
    Title,
    OwnerDisplayName,
    CreationDate,
    AnswerCount,
    ClosedPostCount,
    UpvoteCount
FROM 
    PostStats
ORDER BY 
    UpvoteCount DESC, 
    ClosedPostCount DESC
LIMIT 10;
