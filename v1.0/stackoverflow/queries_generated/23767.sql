WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        SUM(CASE 
                WHEN v.VoteTypeId = 2 THEN 1
                WHEN v.VoteTypeId = 3 THEN -1
                ELSE 0 
            END) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),

RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),

PostHistoryInfo AS (
    SELECT 
        postHistory.PostId,
        Max(postHistory.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory postHistory
    JOIN 
        PostHistoryTypes pht ON postHistory.PostHistoryTypeId = pht.Id
    GROUP BY 
        postHistory.PostId
),

CombinedData AS (
    SELECT 
        upv.UserId,
        upv.DisplayName,
        rpa.PostId,
        rpa.Title,
        rpa.CreationDate AS PostCreationDate,
        rpa.ViewCount,
        rpa.Score,
        COALESCE(ph.LastEditDate, 'No Edits') AS LastEditDate,
        COALESCE(ph.HistoryTypes, 'No History') AS HistoryTypes,
        us.UpVotes,
        us.DownVotes,
        us.NetVotes
    FROM 
        UserVoteStats us
    JOIN 
        RecentPostActivity rpa ON us.UserId = rpa.OwnerUserId
    LEFT JOIN 
        PostHistoryInfo ph ON rpa.PostId = ph.PostId
)

SELECT 
    d.UserId,
    d.DisplayName,
    d.Title,
    d.PostCreationDate,
    d.ViewCount,
    d.Score,
    CASE 
        WHEN d.LastEditDate = 'No Edits' THEN 'Never Edited'
        ELSE TO_CHAR(d.LastEditDate, 'YYYY-MM-DD HH24:MI:SS')
    END AS LastEditInfo,
    d.HistoryTypes,
    COALESCE(d.UpVotes, 0) AS TotalUpVotes,
    COALESCE(d.DownVotes, 0) AS TotalDownVotes,
    d.NetVotes,
    CASE 
        WHEN d.NetVotes > 0 THEN 'Positive'
        WHEN d.NetVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteStatus
FROM 
    CombinedData d
WHERE 
    d.Score > 0
ORDER BY 
    d.Score DESC, d.ViewCount DESC;

-- Test unique corner case: no users with votes but showing their posts
UNION ALL 
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    'Never Edited' AS LastEditInfo,
    'No History' AS HistoryTypes,
    0 AS TotalUpVotes,
    0 AS TotalDownVotes,
    0 AS NetVotes,
    'Neutral' AS VoteStatus
FROM 
    Users u
JOIN 
    Posts p ON p.OwnerUserId = u.Id
WHERE 
    u.Id NOT IN (SELECT UserId FROM Votes)
AND 
    p.Score > 0
ORDER BY 
    p.Score DESC;

