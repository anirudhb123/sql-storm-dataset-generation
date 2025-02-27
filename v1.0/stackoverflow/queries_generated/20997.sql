WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11, 12, 13)) AS CloseActions,
        MAX(ph.CreationDate) AS LastCloseActionDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        phc.CloseActions,
        phc.LastCloseActionDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryCounts phc ON rp.PostId = phc.PostId
)
SELECT 
    *,
    CASE 
        WHEN CloseActions IS NULL THEN 'Never Closed'
        WHEN CloseActions > 0 THEN 'Closed ' || CloseActions || ' times'
        ELSE 'Open'
    END AS ClosureStatus,
    CASE 
        WHEN UpVotes - DownVotes > 10 THEN 'Poll Favorite'
        ELSE 'Standard'
    END AS PostRank,
    CONCAT('Title: ', Title, ', Comments: ', CommentCount) AS TitleWithComments
FROM 
    CombinedData
WHERE 
    rn = 1
ORDER BY 
    UpVotes - DownVotes DESC, LastCloseActionDate
LIMIT 20;

