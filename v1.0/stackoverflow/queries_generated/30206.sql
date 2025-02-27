WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Select Questions only

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.Score,
        COALESCE(p2.AcceptedAnswerId, -1),
        p2.ParentId,
        rp.Level + 1
    FROM 
        Posts p2
    INNER JOIN RecursivePosts rp ON p2.ParentId = rp.Id
)
, PostStats AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.Level,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        RecursivePosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.Id
    LEFT JOIN 
        Votes v ON v.PostId = rp.Id
    GROUP BY 
        rp.Id, rp.Title, rp.Score, rp.Level
)
, BadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
, TypeVoteSummary AS (
    SELECT 
        p.PostTypeId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.PostTypeId
)
SELECT 
    ps.Title,
    ps.Score,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    bc.BadgeCount,
    ts.TotalUpVotes,
    ts.TotalDownVotes,
    ts.TotalVotes
FROM 
    PostStats ps
LEFT JOIN 
    Users u ON ps.Id IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = ps.Id)
LEFT JOIN 
    BadgeCounts bc ON u.Id = bc.UserId
LEFT JOIN 
    TypeVoteSummary ts ON ts.PostTypeId = (
        SELECT 
            PostTypeId 
        FROM 
            Posts 
        WHERE 
            Id = ps.Id
    )
WHERE 
    ps.Score > 0
    AND ps.CommentCount > 5
    AND (bc.BadgeCount IS NOT NULL OR ps.UpVoteCount > 10)
ORDER BY 
    ps.Score DESC, 
    ps.CommentCount DESC, 
    ps.Title;
This query performs a series of operations including recursive CTEs to handle post relationships, aggregates post statistics with commentary and voting details, counts user badges, and summarizes vote types, ultimately filtering to show only pertinent results based on score and engagement.
