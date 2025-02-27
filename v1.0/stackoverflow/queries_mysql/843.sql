
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        @row_number := IF(@current_user_id = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @current_user_id := p.OwnerUserId,
        COALESCE(up.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(down.DownVoteCount, 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS UpVoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            PostId
    ) up ON p.Id = up.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS DownVoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 3 
        GROUP BY 
            PostId
    ) down ON p.Id = down.PostId,
    (SELECT @row_number := 0, @current_user_id := NULL) AS vars
),
PostComments AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS ClosedCount 
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.UpVoteCount,
    rp.DownVoteCount,
    pc.CommentCount,
    COALESCE(cp.ClosedCount, 0) AS ClosedCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 3
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC;
