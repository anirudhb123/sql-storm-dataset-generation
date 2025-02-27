WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        0 AS Level,
        p.Title,
        p.CreationDate,
        p.Score
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        rph.Level + 1,
        p.Title,
        p.CreationDate,
        p.Score
    FROM 
        Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.PostCount,
        u.TotalBounty,
        u.UpVotes,
        u.DownVotes,
        RANK() OVER (ORDER BY u.UpVotes DESC) AS UpVoteRank,
        RANK() OVER (ORDER BY u.DownVotes ASC) AS DownVoteRank
    FROM 
        UserActivity u
    WHERE 
        u.PostCount > 0
),
PostStats AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.CreationDate,
        ph.Score,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COALESCE(p.CommunityOwnedDate, '-1') AS CommunityOwnedDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ph.PostId) AS CommentCount
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        Posts p ON ph.PostId = p.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.CommentCount,
    uu.DisplayName,
    uu.PostCount,
    uu.TotalBounty,
    uu.UpVotes,
    uu.DownVotes,
    tt.UpVoteRank,
    tt.DownVoteRank
FROM 
    PostStats ps
JOIN 
    TopUsers uu ON ps.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = uu.UserId)
JOIN 
    TopUsers tt ON tt.UpVoteRank <= 10 OR tt.DownVoteRank <= 10
WHERE 
    ps.AcceptedAnswerId = -1 
    AND ps.CreationDate >= NOW() - INTERVAL '1 year' 
ORDER BY 
    ps.Score DESC, 
    ps.CommentCount DESC;

