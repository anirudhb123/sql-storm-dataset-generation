WITH RecursivePostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id
), 
UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(up.VoteCount, 0)) AS TotalUpVotes,
        SUM(COALESCE(down.VoteCount, 0)) AS TotalDownVotes,
        RANK() OVER (ORDER BY SUM(COALESCE(up.VoteCount, 0)) DESC) AS UpvoteRank
    FROM 
        Users u
    LEFT JOIN 
        RecursivePostVotes up ON u.Id = p.OwnerUserId
    LEFT JOIN 
        RecursivePostVotes down ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.Comment
),
MixedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(cr.CloseCount, 0) AS CloseCount,
        COALESCE(rv.VoteCount, 0) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        CloseReasons cr ON p.Id = cr.PostId
    LEFT JOIN 
        RecursivePostVotes rv ON p.Id = rv.PostId
    WHERE 
        p.ViewCount > 100 AND (p.CreatedDate >= CURRENT_DATE - INTERVAL '30 days' OR p.Score > 0)
)
SELECT 
    mp.Title,
    mp.CloseCount,
    mp.TotalVotes,
    ur.DisplayName,
    ur.TotalUpVotes,
    ur.TotalDownVotes
FROM 
    MixedPosts mp
JOIN 
    UserRankings ur ON mp.PostId = ur.UserId
WHERE 
    mp.CloseCount > 0
ORDER BY 
    mp.TotalVotes DESC, ur.UpvoteRank
LIMIT 20;
