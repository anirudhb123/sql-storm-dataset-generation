WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id 
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    r.PostId,
    r.Title,
    COALESCE(u.DisplayName, 'Anonymous') AS OwnerName,
    r.Score,
    r.ViewCount,
    r.Rank,
    r.CommentCount,
    cp.LastClosedDate
FROM 
    RankedPosts r
LEFT JOIN 
    Users u ON r.Rank = 1 AND r.PostId = u.Id
LEFT JOIN 
    ClosedPosts cp ON r.PostId = cp.PostId
WHERE 
    r.Rank <= 5
ORDER BY 
    r.Score DESC
LIMIT 10;

WITH UserVoteSummary AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.Location,
    COALESCE(rv.UpVoteCount, 0) AS UpVotes,
    COALESCE(rv.DownVoteCount, 0) AS DownVotes,
    CASE 
        WHEN rv.TotalVotes IS NULL THEN 'No votes registered'
        ELSE 'Votes registered'
    END AS VoteStatus
FROM 
    Users u
LEFT JOIN 
    UserVoteSummary rv ON u.Id = rv.UserId
WHERE 
    u.Reputation > 2000
ORDER BY 
    u.Reputation DESC
LIMIT 5;
