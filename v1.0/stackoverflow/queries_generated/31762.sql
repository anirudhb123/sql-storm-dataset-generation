WITH RECURSIVE UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        CAST(0 AS int) AS Level,
        DisplayName
    FROM Users
    WHERE Reputation > 1000
    UNION ALL
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        CAST(ur.Level + 1 AS int),
        u.DisplayName
    FROM Users u
    JOIN UserReputation ur ON u.Id <> ur.UserId
    WHERE u.Reputation > ur.Reputation
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.CreationDate,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    COALESCE(phd.EditCount, 0) AS EditCount,
    COALESCE(phd.LastEditDate, 'No Edits') AS LastEditDate,
    COALESCE(phd.HistoryTypes, 'N/A') AS HistoryTypes,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM UserReputation ur
JOIN TopPosts tp ON ur.UserId = tp.OwnerUserId
LEFT JOIN PostHistoryDetails phd ON tp.PostId = phd.PostId
WHERE ur.Reputation > 1500
  AND tp.Rank = 1
ORDER BY ur.Reputation DESC
LIMIT 10;
