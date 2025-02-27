WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2) -- only Questions and Answers
    GROUP BY 
        p.Id, p.PostTypeId, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE((SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = u.Id), 0) AS BadgeCount
    FROM 
        Users u
    WHERE 
        u.Reputation > 50 -- Get only active users with reputation > 50
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 4 THEN ph.CreationDate END) AS LastTitleEdit,
        MAX(CASE WHEN ph.PostHistoryTypeId BETWEEN 10 AND 11 THEN ph.CreationDate END) AS LastStatusChangeDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.BadgeCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(PHD.LastEditDate, 'No Edits') AS LastEditDate,
    COALESCE(PHD.LastTitleEdit, 'Never Edited') AS LastTitleEdit,
    COALESCE(PHD.LastStatusChangeDate, 'Still Active') AS LastStatusChange
FROM 
    RankedPosts rp
JOIN 
    UserReputation up ON rp.OwnerUserId = up.UserId
LEFT JOIN 
    PostHistoryDetails PHD ON rp.PostId = PHD.PostId
WHERE 
    rp.Rank <= 3 -- Top 3 posts per user
ORDER BY 
    up.Reputation DESC, rp.Score DESC, rp.CreationDate DESC;

-- Extra corner case demonstrating handling of NULL values
SELECT 
    DISTINCT pn.PostId,
    (CASE 
        WHEN pn.CreationDate IS NULL THEN 'Created Before 2023'
        ELSE 'Created After 2023'
    END) AS CreationPeriod
FROM 
    Posts pn
WHERE 
    pn.CreationDate IS NOT NULL
    AND pn.ViewCount IS NOT NULL
    AND EXISTS (
        SELECT 1 
        FROM Comments c 
        WHERE c.PostId = pn.Id 
        HAVING COUNT(*) > 0
    )
ORDER BY 
    CreationPeriod, pn.ViewCount DESC;
