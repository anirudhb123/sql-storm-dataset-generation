WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 100
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotes, -- Count of Upvotes
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS DownVotes, -- Count of Downvotes
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId
    LEFT JOIN 
        Badges b ON b.UserId = rp.OwnerUserId
    WHERE 
        rp.rn = 1 -- Only consider the most recent post per user
    GROUP BY 
        rp.PostId, rp.Title
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and reopened posts
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    COALESCE(bp.ClosedCount, 0) AS ClosedCount,
    COALESCE(bp.ReopenedCount, 0) AS ReopenedCount,
    CASE 
        WHEN ps.UpVotes = 0 AND ps.DownVotes = 0 THEN 'No Votes'
        WHEN ps.UpVotes > ps.DownVotes THEN 'More Upvotes'
        ELSE 'More Downvotes'
    END AS VoteSummary,
    STUFF((SELECT ', ' + u.DisplayName 
           FROM Users u 
           WHERE u.Id IN (SELECT DISTINCT bp.UserId FROM ClosedPosts bp WHERE bp.PostId = ps.PostId)
           FOR XML PATH('')), 1, 2, '') AS UsersClosed
FROM 
    PostStats ps
LEFT JOIN (
    SELECT 
        cp.PostId,
        COUNT(CASE WHEN cp.Comment IS NOT NULL AND cp.CreationDate IS NOT NULL THEN 1 END) AS ClosedCount,
        COUNT(CASE WHEN cp.Comment IS NULL AND cp.CreationDate IS NOT NULL THEN 1 END) AS ReopenedCount
    FROM 
        ClosedPosts cp
    GROUP BY 
        cp.PostId
) bp ON ps.PostId = bp.PostId
ORDER BY 
    ps.UpVotes DESC, ps.CommentCount DESC;
