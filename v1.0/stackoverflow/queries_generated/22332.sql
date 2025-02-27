WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
        AND u.Reputation > 100 -- Only consider users with reputation over 100
),
PostHistories AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FilteredPostHistories AS (
    SELECT 
        Ph.PostId,
        Ph.ClosedDate,
        Ph.ReopenedDate,
        Ph.CloseCount,
        CASE 
            WHEN Ph.ClosedDate IS NOT NULL AND Ph.ReopenedDate IS NOT NULL AND Ph.ClosedDate < Ph.ReopenedDate THEN 'Reopened'
            WHEN Ph.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS Status
    FROM 
        PostHistories Ph
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Reputation,
        fph.ClosedDate,
        fph.ReopenedDate,
        fph.Status,
        CASE 
            WHEN fph.Status = 'Closed' THEN NULL
            ELSE (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId)
        END AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        FilteredPostHistories fph ON rp.PostId = fph.PostId
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.ViewCount,
    cd.Reputation,
    cd.Status,
    COALESCE(cd.CommentCount, 0) AS TotalComments,
    CASE 
        WHEN cd.Reputation IS NULL THEN 'Unknown Reputation'
        ELSE CONCAT(cd.Reputation, ' Reputation Points')
    END AS ReputationDisplay
FROM 
    CombinedData cd
WHERE 
    cd.Rank = 1 -- Get the top post per user
ORDER BY 
    cd.ViewCount DESC
LIMIT 100;

This SQL query performs a variety of operations on the provided StackOverflow schema and makes use of CTEs, window functions, conditional logic, and outer joins to produce a comprehensive report on posts and their related metrics. The query collects details about the most popular post per user along with the status of any closures or reopenings, while accommodating for null logic and producing a display-friendly format for reputation.
