WITH RecursivePostCTE AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        CAST(0 AS INT) AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Start with Questions
    UNION ALL
    SELECT
        p.ParentId AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        Level + 1
    FROM Posts p
    JOIN RecursivePostCTE r ON p.Id = r.PostId
    WHERE p.ParentId IS NOT NULL
),
PostVotes AS (
    SELECT
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
PostHistoryInfo AS (
    SELECT
        ph.PostId,
        ph.CreationDate,
        pht.Name AS HistoryTypeName,
        COUNT(*) AS HistoryCount
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId, ph.CreationDate, pht.Name
),
CombinedPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE(pv.UpVotes, 0) AS UpVotes,
        COALESCE(pv.DownVotes, 0) AS DownVotes,
        COUNT(DISTINCT ph.PostHistoryTypeId) AS TotalHistoryTypes
    FROM RecursivePostCTE rp
    LEFT JOIN PostVotes pv ON rp.PostId = pv.PostId
    LEFT JOIN PostHistoryInfo ph ON rp.PostId = ph.PostId
    GROUP BY
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        pv.UpVotes,
        pv.DownVotes
)
SELECT
    cp.PostId,
    cp.Title,
    cp.CreationDate,
    cp.ViewCount,
    cp.Score,
    cp.UpVotes,
    cp.DownVotes,
    cp.TotalHistoryTypes,
    CASE 
        WHEN cp.Score > 100 THEN 'Highly Active'
        WHEN cp.Score BETWEEN 50 AND 100 THEN 'Moderately Active'
        ELSE 'Low Activity'
    END AS ActivityLevel,
    CASE
        WHEN ER.Level IS NOT NULL THEN 'Parent Exists'
        ELSE 'No Parent'
    END AS ParentExistenceStatus
FROM CombinedPosts cp
LEFT JOIN RecursivePostCTE ER ON cp.PostId = ER.PostId AND ER.Level = 1
WHERE cp.TotalHistoryTypes > 5
ORDER BY cp.Score DESC, cp.CreationDate DESC;

