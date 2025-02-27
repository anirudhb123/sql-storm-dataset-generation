WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS UpVotes FROM Votes WHERE VoteTypeId = 2 GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.ViewCount, v.UpVotes, v.DownVotes
),
PostHistoryStats AS (
    SELECT 
        Ph.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MAX(Ph.CreationDate) AS LastModified
    FROM 
        PostHistory Ph
    GROUP BY 
        Ph.PostId, Ph.PostHistoryTypeId
),
FinalStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.Rank,
        COALESCE(ps.HistoryCount, 0) AS HistoryCount,
        ps.LastModified
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT PostId, SUM(HistoryCount) AS HistoryCount, MAX(LastModified) AS LastModified FROM PostHistoryStats GROUP BY PostId) ps ON rp.PostId = ps.PostId
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.ViewCount,
    fs.UpVotes,
    fs.DownVotes,
    fs.Rank,
    fs.HistoryCount,
    fs.LastModified,
    CASE 
        WHEN fs.HistoryCount > 5 THEN 'Highly Active'
        WHEN fs.HistoryCount BETWEEN 1 AND 5 THEN 'Moderately Active'
        ELSE 'Inactive'
    END AS ActivityLevel
FROM 
    FinalStats fs
WHERE 
    fs.Rank <= 10
ORDER BY 
    fs.ViewCount DESC, fs.LastModified DESC
OPTION (RECOMPILE);
