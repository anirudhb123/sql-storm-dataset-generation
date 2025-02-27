
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser,
        (SELECT COUNT(v.Id) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(v.Id) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
      AND 
        p.ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE CreationDate >= NOW() - INTERVAL 30 DAY)
),
PostDetails AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankPerUser,
        rp.UpvoteCount,
        rp.DownvoteCount,
        COALESCE(cu.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users cu ON rp.PostID = cu.Id
    WHERE 
        rp.RankPerUser <= 5
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        p.Title
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 OR ph.PostHistoryTypeId = 11
)
SELECT 
    pd.PostID,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.UpvoteCount,
    pd.DownvoteCount,
    ph.Comment AS ClosureComment,
    COUNT(DISTINCT ph.PostId) AS TotalCloseActions
FROM 
    PostDetails pd
LEFT JOIN 
    ClosedPostHistory ph ON pd.PostID = ph.PostId
GROUP BY 
    pd.PostID, pd.Title, pd.OwnerDisplayName, pd.CreationDate, pd.Score, pd.ViewCount, pd.UpvoteCount, pd.DownvoteCount, ph.Comment
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
