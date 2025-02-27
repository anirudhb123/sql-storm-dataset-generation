WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(case when v.VoteTypeId = 2 then 1 else 0 end), 0) AS UpVoteCount,
        COALESCE(SUM(case when v.VoteTypeId = 3 then 1 else 0 end), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.UpVoteCount - ps.DownVoteCount DESC) AS Rank
    FROM 
        PostStats ps
)
SELECT 
    uvs.UserId,
    uvs.DisplayName,
    rps.PostId,
    rps.CommentCount,
    rps.UpVoteCount,
    rps.DownVoteCount,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    cp.FirstClosedDate
FROM 
    UserVoteStats uvs
LEFT JOIN 
    RankedPosts rps ON uvs.UserId = rps.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON rps.PostId = cp.PostId
WHERE 
    rps.Rank <= 5 OR rps.Rank IS NULL
ORDER BY 
    uvs.Reputation DESC, 
    rps.UpVoteCount - rps.DownVoteCount DESC;
