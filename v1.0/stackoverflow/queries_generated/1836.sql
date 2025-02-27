WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 12)) AS CloseVoteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
CombinedData AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        ph.LastClosedDate,
        ph.LastReopenedDate,
        ph.CloseVoteCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN ph.LastClosedDate IS NOT NULL AND (ph.LastReopenedDate IS NULL OR ph.LastClosedDate > ph.LastReopenedDate) 
            THEN 'Closed' 
            ELSE 'Open' 
        END AS Status
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryData ph ON rp.Id = ph.PostId
)
SELECT 
    c.Location,
    COUNT(*) AS PostCount,
    AVG(CASE WHEN Status = 'Open' THEN Score ELSE NULL END) AS AvgOpenScore,
    AVG(CASE WHEN Status = 'Closed' THEN Score ELSE NULL END) AS AvgClosedScore,
    SUM(UpVoteCount) AS TotalUpVotes,
    SUM(DownVoteCount) AS TotalDownVotes
FROM 
    CombinedData cd
JOIN 
    Users u ON cd.OwnerUserId = u.Id
GROUP BY 
    c.Location
HAVING 
    COUNT(*) > 5
ORDER BY 
    PostCount DESC
LIMIT 10;
