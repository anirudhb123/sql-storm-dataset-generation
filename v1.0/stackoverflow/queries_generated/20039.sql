WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.Score > 0 -- Positive score
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.CreationDate, ph.UserDisplayName, ph.Comment
), 
PostWithClosure AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        CASE 
            WHEN COALESCE(cp.CloseCount, 0) > 0 THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.Author,
    pwc.CreationDate,
    pwc.CommentCount,
    pwc.UpVotes,
    pwc.DownVotes,
    pwc.CloseCount,
    pwc.PostStatus,
    CASE 
        WHEN pwc.PostStatus = 'Closed' THEN 
            'This post is closed with ' || pwc.CloseCount || ' close votes'
        ELSE 
            'This post is active and has received ' || pwc.CommentCount || ' comments'
    END AS StatusMessage
FROM 
    PostWithClosure pwc
WHERE 
    pwc.UpVotes > pwc.DownVotes -- More upvotes than downvotes
ORDER BY 
    pwc.CreationDate DESC, 
    pwc.UpVotes DESC;
