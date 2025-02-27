WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypeNames,
        COUNT(CASE WHEN ph.CreationDate < NOW() - INTERVAL '30 days' THEN 1 END) AS OldEdits
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    r.CreationDate,
    r.CommentCount,
    r.PostRank,
    u.UserId,
    u.DisplayName AS UserDisplayName,
    u.UpVotes,
    u.DownVotes,
    COALESCE(phd.HistoryTypeNames, 'No History') AS HistoryDetails,
    phd.OldEdits
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    PostHistoryDetails phd ON r.PostId = phd.PostId
WHERE 
    r.PostRank <= 5
ORDER BY 
    r.Score DESC, 
    r.CreationDate DESC;
