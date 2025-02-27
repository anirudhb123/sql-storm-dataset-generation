
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 MONTH)
    GROUP BY 
        v.PostId
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name SEPARATOR ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LatestActionDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Owner,
        COALESCE(rv.UpVotes, 0) AS UpVotes,
        COALESCE(rv.DownVotes, 0) AS DownVotes,
        pha.HistoryTypes,
        pha.LatestActionDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    LEFT JOIN 
        PostHistoryAggregated pha ON rp.PostId = pha.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    *,
    (UpVotes - DownVotes) AS VoteBalance,
    CASE 
        WHEN LatestActionDate IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS Status
FROM 
    FinalResults
ORDER BY 
    Score DESC, UpVotes DESC;
