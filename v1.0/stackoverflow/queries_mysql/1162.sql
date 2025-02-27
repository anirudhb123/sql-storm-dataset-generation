
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
        AND p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
),
PostVoteSummary AS (
    SELECT 
        pv.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes pv
    JOIN 
        VoteTypes vt ON pv.VoteTypeId = vt.Id
    GROUP BY 
        pv.PostId
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(cr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS UNSIGNED) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(pvs.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(pvs.DownVoteCount, 0) AS DownVoteCount,
    COALESCE(pcr.CloseReasons, 'Not Closed') AS CloseReasons,
    CASE 
        WHEN rp.RankByScore <= 3 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    PostCloseReasons pcr ON rp.PostId = pcr.PostId
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC;
