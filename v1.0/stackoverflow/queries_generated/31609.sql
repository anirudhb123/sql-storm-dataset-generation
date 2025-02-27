WITH RECURSIVE UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        1 AS Level
    FROM Users
    WHERE Reputation > 5000
    
    UNION ALL
    
    SELECT 
        p.OwnerUserId,
        u.Reputation,
        u.CreationDate,
        Level + 1
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    JOIN UserReputation ur ON ur.UserId = p.OwnerUserId
    WHERE ur.Level < 3
),
FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagNames
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN STRING_TO_ARRAY(p.Tags, ',') AS tag_array ON (TRUE)
    LEFT JOIN Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag_array)
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
      AND p.Score > 0
      AND (p.ClosedDate IS NULL OR p.ClosedDate < NOW())
    GROUP BY p.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 1 THEN ph.CreationDate END) AS InitialTitleDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(DISTINCT ph.UserId) AS EditCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    up.UserId,
    up.Reputation,
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fps.TagNames,
    phs.InitialTitleDate,
    phs.CloseReopenCount,
    phs.EditCount,
    ROW_NUMBER() OVER (PARTITION BY up.UserId ORDER BY fp.Score DESC) AS PostRank
FROM UserReputation up
JOIN FilteredPosts fp ON up.UserId = fp.OwnerUserId
LEFT JOIN PostHistorySummary phs ON fp.PostId = phs.PostId
WHERE up.Reputation BETWEEN 5000 AND 10000
ORDER BY up.Reputation DESC, PostRank;
