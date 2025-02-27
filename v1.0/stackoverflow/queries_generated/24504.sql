WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Count of upvotes
        SUM(v.VoteTypeId = 3) AS DownVotes, -- Count of downvotes
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN AVG(UPTIME) < 1 THEN 'Underperforming'
            WHEN AVG(UPTIME) >= 1 AND AVG(UPTIME) < 3 THEN 'Moderately Performing'
            ELSE 'High Performer'
        END AS PerformanceCategory,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users U ON rp.OwnerUserId = U.Id
), PostInteraction AS (
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerDisplayName,
        r.CreationDate,
        r.PerformanceCategory,
        r.CommentCount,
        r.UpVotes,
        r.DownVotes,
        CASE 
            WHEN r.CommentCount IS NULL THEN 'No Comments'
            ELSE CONCAT(r.CommentCount, ' Comments')
        END AS CommentStatus,
        COALESCE(r.UpVotes - r.DownVotes, 0) AS NetVotes,
        DENSE_RANK() OVER (ORDER BY r.UpVotes DESC) AS VoteRank
    FROM 
        RecentPosts r
)
SELECT 
    p.PostId,
    p.Title,
    p.OwnerDisplayName,
    p.CreationDate,
    p.PerformanceCategory,
    p.CommentStatus,
    p.NetVotes,
    CASE 
        WHEN p.VoteRank < 5 THEN 'Top Posts'
        ELSE 'Other Posts'
    END AS RankingCategory
FROM 
    PostInteraction p
WHERE 
    p.NetVotes >= 1
ORDER BY 
    p.NetVotes DESC,
    p.CreationDate ASC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;

-- Additional performance logging that captures unusual activities or anomalies
WITH Anomalies AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS HistoryCount,
        CASE
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Close/Reopen Activity'
            WHEN ph.PostHistoryTypeId = 12 THEN 'Deleted'
            ELSE 'Other Changes'
        END AS ChangeType
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= (SELECT MIN(CreationDate) FROM Posts)
)
SELECT 
    a.PostId,
    MAX(a.ChangeType) AS MostRecentChangeType,
    MAX(a.CreationDate) AS LatestChangeDate,
    COUNT(a.PostId) AS TotalHistoryEntries
FROM 
    Anomalies a
GROUP BY 
    a.PostId
HAVING 
    COUNT(a.PostId) > 5 -- Only include posts with more than 5 changes
ORDER BY 
    TotalHistoryEntries DESC;
