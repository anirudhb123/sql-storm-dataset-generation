WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserVoteSummary AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 9 THEN v.BountyAmount ELSE 0 END) AS TotalBounty
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UPVOTE_COUNT,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DOWNVOTE_COUNT,
        SUM(b.Gold + b.Silver + b.Bronze) AS TotalBadges
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (
            SELECT 
                UserId,
                SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS Gold,
                SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS Silver,
                SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS Bronze
            FROM 
                Badges
            GROUP BY 
                UserId
        ) b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UPVOTE_COUNT,
    ps.DOWNVOTE_COUNT,
    COALESCE(u.UpVotes, 0) AS TotalUpVotes,
    COALESCE(u.DownVotes, 0) AS TotalDownVotes,
    COALESCE(u.TotalBounty, 0) AS TotalBounty,
    r.Level AS PostLevel
FROM 
    PostStatistics ps
LEFT JOIN 
    UserVoteSummary u ON ps.OwnerUserId = u.UserId
LEFT JOIN 
    RecursivePostHierarchy r ON ps.PostId = r.PostId
WHERE 
    ps.CommentCount > 0
ORDER BY 
    ps.UPVOTE_COUNT DESC, 
    ps.DOWNVOTE_COUNT ASC;
