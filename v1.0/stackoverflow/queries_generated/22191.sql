WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerDisplayName,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.Score IS NOT NULL
    AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.PostTypeId,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 10
    AND 
        rp.UpVotes - rp.DownVotes > 0
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastChangeDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeletionUndeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalReport AS (
    SELECT 
        fp.Title,
        fp.OwnerDisplayName,
        fp.CreationDate,
        pha.LastChangeDate,
        pha.ClosureReopenCount,
        pha.DeletionUndeleteCount,
        CASE 
            WHEN pha.ClosureReopenCount > 5 THEN 'Highly Active'
            WHEN pha.ClosureReopenCount BETWEEN 3 AND 5 THEN 'Moderately Active'
            ELSE 'Inactive'
        END AS ActivityLevel
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostHistoryAnalysis pha ON fp.Id = pha.PostId
)
SELECT 
    fr.*,
    CASE 
        WHEN fr.ClosureReopenCount IS NULL THEN 'No Activity'
        ELSE 'Activity Recorded'
    END AS ActivityStatus,
    JSON_BUILD_OBJECT(
        'Title', fr.Title,
        'Owner', fr.OwnerDisplayName,
        'CreationDate', fr.CreationDate,
        'LastChangeDate', fr.LastChangeDate,
        'ActivityLevel', fr.ActivityLevel,
        'ActivityStatus', CASE 
            WHEN fr.ClosureReopenCount IS NOT NULL THEN 'Activity Recorded' 
            ELSE 'No Activity' 
        END
    ) AS ReportJson
FROM 
    FinalReport fr
ORDER BY 
    fr.CreationDate DESC
LIMIT 50
OFFSET 0;
