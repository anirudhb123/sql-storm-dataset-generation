
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 6 MONTH
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (6, 10, 12) THEN 1 END) AS ClosureVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 6 MONTH
    GROUP BY 
        v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name ORDER BY pht.Name ASC SEPARATOR ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.ClosureVotes,
    phd.HistoryTypes,
    phd.HistoryCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
