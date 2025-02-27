WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id 
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentEdit
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10) 
),
LatestPostHistory AS (
    SELECT 
        p.Id AS PostId,
        phd.PostHistoryTypeId,
        phd.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistoryDetails phd ON p.Id = phd.PostId
    WHERE 
        phd.RecentEdit = 1
)
SELECT 
    u.DisplayName,
    ups.UpVotesCount,
    ups.DownVotesCount,
    pp.PostId,
    pp.CreationDate,
    p.Title,
    p.ViewCount,
    pp.PostHistoryTypeId,
    COALESCE(pph.Name, 'No History') AS LastPostAction
FROM 
    UserVoteStats ups
JOIN 
    Posts p ON ups.UserId = p.OwnerUserId
LEFT JOIN 
    LatestPostHistory pp ON p.Id = pp.PostId
LEFT JOIN 
    PostHistoryTypes pph ON pp.PostHistoryTypeId = pph.Id
WHERE 
    p.ViewCount > 1000
ORDER BY 
    ups.UpVotesCount DESC, 
    ups.DownVotesCount ASC, 
    pp.CreationDate DESC
LIMIT 50;
