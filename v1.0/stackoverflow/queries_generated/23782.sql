WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS RankScore,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotesCount,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 YEAR'
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, ', ') AS HistoryComments,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    COALESCE(ph.HistoryComments, 'No history available') AS PostHistory,
    COALESCE(ph.LastClosedDate, 'Never closed') AS LastClosed,
    ph.CloseReopenCount AS CloseReopenOccurrences,
    rp.UpVotesCount,
    rp.DownVotesCount,
    CASE 
        WHEN rp.RankScore <= 5 THEN 'Top Performer'
        WHEN rp.RankScore <= 10 THEN 'Mid Performer'
        ELSE 'Low Performer'
    END AS PerformanceCategory,
    (SELECT 
        STRING_AGG(TagName, ', ') 
     FROM 
        TagStatistics 
     WHERE 
        PostCount > 5) AS PopularTags
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
WHERE 
    rp.RankScore <= 10 OR ph.CloseReopenCount > 2
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
