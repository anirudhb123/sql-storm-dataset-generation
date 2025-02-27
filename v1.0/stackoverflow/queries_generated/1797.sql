WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
        AND p.PostTypeId = 1 -- Only questions
),
ClosedPostHistory AS (
    SELECT
        ph.PostId,
        ph.UserId,
        STRING_AGG(DISTINCT pr.Name, ', ') AS CloseReasons,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pr ON ph.PostHistoryTypeId = pr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId, ph.UserId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(cph.CloseReasons, 'None') AS CloseReasons,
        COALESCE(cph.CloseCount, 0) AS CloseCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPostHistory cph ON rp.PostId = cph.PostId
    WHERE 
        rp.Rank <= 50
)

SELECT 
    PostId,
    Title,
    ViewCount,
    Score,
    UpVotes,
    DownVotes,
    CloseReasons,
    CloseCount
FROM 
    FinalResults
WHERE 
    CloseCount > 0 OR CloseReasons != 'None'
ORDER BY 
    Score DESC, ViewCount DESC;
