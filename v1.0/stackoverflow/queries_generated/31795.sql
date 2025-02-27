WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS Rank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVoteCount,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        PHR.Name AS HistoryType,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHR ON ph.PostHistoryTypeId = PHR.Id
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.CommentCount,
        COALESCE(phc.HistoryType, 'No History') AS LatestHistoryType,
        COALESCE(phc.HistoryDate, '1970-01-01 00:00:00') AS LatestHistoryDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryCTE phc ON rp.PostId = phc.PostId AND phc.HistoryRank = 1
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.ViewCount,
    cd.UpVoteCount,
    cd.DownVoteCount,
    cd.CommentCount,
    cd.LatestHistoryType,
    cd.LatestHistoryDate,
    CASE 
        WHEN cd.UpVoteCount > cd.DownVoteCount THEN 'Positive Feedback'
        WHEN cd.UpVoteCount < cd.DownVoteCount THEN 'Negative Feedback'
        ELSE 'No Feedback'
    END AS FeedbackType
FROM 
    CombinedData cd
WHERE 
    cd.Rank <= 10
ORDER BY 
    cd.ViewCount DESC;
