WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), PostStats AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.UpVoteCount = 0 AND rp.DownVoteCount = 0 THEN NULL
            ELSE COALESCE(rp.UpVoteCount * 1.0 / NULLIF(rp.UpVoteCount + rp.DownVoteCount, 0), 0) END AS UpVoteRatio
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
), PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) -- Edit Title, Edit Body, Edit Tags, Suggested Edit Applied
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)

SELECT 
    p.Title,
    p.CreationDate,
    ps.ViewCount,
    ps.AnswerCount,
    ps.UpVoteRatio,
    COALESCE(SUM(CASE WHEN phs.PostHistoryTypeId IN (4, 5, 6) THEN phs.EditCount ELSE 0 END), 0) AS TotalEdits,
    MAX(phs.LastEditDate) AS MostRecentEdit,
    CASE 
        WHEN ps.UpVoteRatio IS NULL THEN 'No votes'
        WHEN ps.UpVoteRatio > 0.5 THEN 'Well-received'
        ELSE 'Needs improvement' END AS ReceptionStatus
FROM 
    PostStats ps
JOIN 
    Posts p ON ps.PostID = p.Id
LEFT JOIN 
    PostHistorySummary phs ON p.Id = phs.PostId
WHERE 
    ps.UpVoteCount > 0
GROUP BY 
    p.Title, ps.ViewCount, ps.AnswerCount, ps.UpVoteRatio
HAVING 
    COUNT(DISTINCT phs.PostHistoryTypeId) > 2 -- Ensure there have been multiple types of edits
ORDER BY 
    ps.AnswerCount DESC,
    ps.ViewCount DESC;
