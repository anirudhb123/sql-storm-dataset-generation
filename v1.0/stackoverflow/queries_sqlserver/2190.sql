
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL 
        AND p.CreationDate >= DATEADD(year, -1, CAST('2024-10-01 12:34:56' AS DATETIME))
), 
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, CAST('2024-10-01 12:34:56' AS DATETIME))
    GROUP BY 
        v.PostId
), 
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rv.UpVotes,
        rv.DownVotes,
        COALESCE(rv.UpVotes - rv.DownVotes, 0) AS NetVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    WHERE 
        rp.Rank <= 10
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(ph.Id) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.UpVotes,
    pd.DownVotes,
    pd.NetVotes,
    COALESCE(cp.CloseCount, 0) AS TotalClosures
FROM 
    PostDetails pd
LEFT JOIN 
    ClosedPosts cp ON pd.PostId = cp.PostId
ORDER BY 
    pd.NetVotes DESC, 
    pd.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
