mysql
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
),
PostDetails AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostID) AS CommentCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Votes v 
            WHERE v.PostId = rp.PostID AND v.VoteTypeId IN (2, 10) 
        ), 0) AS UpvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        GROUP_CONCAT(ph.Comment SEPARATOR ', ') AS Comments,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL 2 YEAR
        AND ph.PostHistoryTypeId IN (10, 11, 12)
    GROUP BY ph.PostId, ph.PostHistoryTypeId, ph.CreationDate
),
FinalResults AS (
    SELECT 
        pd.PostID,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.AnswerCount,
        pd.CommentCount,
        pd.UpvoteCount,
        COALESCE(phd.Comments, 'No changes') AS HistoryComments,
        COALESCE(phd.ChangeCount, 0) AS HistoryChangeCount
    FROM 
        PostDetails pd
    LEFT JOIN 
        PostHistoryDetails phd ON pd.PostID = phd.PostId
)
SELECT 
    FR.PostID,
    FR.Title,
    FR.CreationDate,
    FR.Score,
    FR.ViewCount,
    FR.AnswerCount,
    FR.CommentCount,
    FR.UpvoteCount,
    FR.HistoryComments,
    FR.HistoryChangeCount,
    CASE
        WHEN FR.HistoryChangeCount > 0 THEN 'Modified'
        WHEN FR.CommentCount < 5 THEN 'Low Engagement'
        WHEN FR.Score = 0 THEN 'Neutral'
        ELSE 'Popular'
    END AS EngagementStatus
FROM 
    FinalResults FR
WHERE 
    FR.ViewCount > 100
ORDER BY 
    FR.Score DESC, FR.ViewCount DESC;
