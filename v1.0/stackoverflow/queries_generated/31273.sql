WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.Body,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT ph.PostId) AS EditCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100  -- Consider only users with reputation greater than 100
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS ClosedDate, 
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseHistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Closed posts
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.EditCount,
    up.VoteCount,
    up.UpVoteCount,
    up.DownVoteCount,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    cp.ClosedDate,
    cp.CloseReason
FROM 
    UserMetrics up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId AND cp.CloseHistoryRank = 1  -- Most recent close event
WHERE 
    rp.UserPostRank <= 3  -- Top 3 posts per user
ORDER BY 
    up.Reputation DESC, rp.Score DESC;
