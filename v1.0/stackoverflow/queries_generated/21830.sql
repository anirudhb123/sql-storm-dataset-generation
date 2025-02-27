WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
),
AuthorStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        pt.Name AS PostHistoryTypeName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate < (current_timestamp - INTERVAL '2 days') 
        AND ph.Comment IS NOT NULL
)
SELECT 
    rp.PostId,
    rp.Title,
    ra.UserId,
    a.DisplayName,
    ra.Rank,
    ps.TotalBadges,
    ps.GoldBadges,
    ps.TotalBounties,
    ph.PostHistoryTypeName,
    ph.CreationDate AS HistoryCreationDate,
    ph.UserDisplayName AS HistoryUser,
    ph.HistoryRank
FROM 
    RankedPosts rp
JOIN 
    Users ra ON rp.PostId = ra.Id  -- assuming posts have a reference to the posting user
JOIN 
    AuthorStats ps ON ra.UserId = ps.UserId
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, ps.TotalBadges DESC;

-- Include corner cases with NULL checks and obscure conditions
WITH RecursiveCTE AS (
    SELECT 
        p.Id,
        p.OwnerUserId,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.OwnerUserId IS NOT NULL
    GROUP BY 
        p.Id, p.OwnerUserId, p.Score
)
SELECT 
    r.Id AS PostId,
    r.Score,
    (r.UpVotes - r.DownVotes) AS NetVotes
FROM 
    RecursiveCTE r
WHERE 
    (r.Score IS NULL OR r.Score > 0) 
    AND r.NetVotes IS NOT NULL
    AND r.NetVotes > 10
ORDER BY 
    r.Score DESC;
