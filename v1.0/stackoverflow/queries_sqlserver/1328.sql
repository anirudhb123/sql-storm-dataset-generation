
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) OVER (PARTITION BY p.Id) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) OVER (PARTITION BY p.Id) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
      AND 
        p.ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56'))
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
