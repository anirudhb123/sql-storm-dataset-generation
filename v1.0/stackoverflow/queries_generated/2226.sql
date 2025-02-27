WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPostCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p 
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM PostHistory ph 
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.UpvotedPostCount,
    ups.DownvotedPostCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Author,
    COALESCE(phd.EditCount, 0) AS TotalEdits,
    phd.LastEditDate,
    phd.EditTypes
FROM UserPostStats ups
LEFT JOIN RankedPosts rp ON ups.UserId = rp.Author
LEFT JOIN PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE ups.PostCount > 10
ORDER BY ups.UpvotedPostCount DESC, TotalEdits DESC
LIMIT 100;

-- This query retrieves users with more than 10 posts, calculates their stats,
-- ranks their posts within the year, and gathers post history details. 
