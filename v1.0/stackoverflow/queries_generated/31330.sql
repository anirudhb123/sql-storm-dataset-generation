WITH RecursivePostHierarchy AS (
    SELECT 
        Id, 
        Title, 
        ParentId, 
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId, 
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END) AS PostCount,
        RANK() OVER (ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        COALESCE(SUM(phh.CreationDate IS NOT NULL AND phh.PostHistoryTypeId = 10), 0) AS ClosedCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory phh ON p.Id = phh.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, c.CommentCount, v.VoteCount
)
SELECT 
    p.Title,
    p.CreationDate,
    ps.CommentCount,
    ps.VoteCount,
    cpp.UserId,
    cpp.DisplayName,
    cpp.TotalScore,
    cpp.ReputationRank,
    psh.Level AS PostLevel
FROM 
    PostStatistics ps
INNER JOIN 
    RecursivePostHierarchy psh ON ps.PostId = psh.Id
INNER JOIN 
    UserReputation cpp ON ps.PostId IN (
        SELECT AcceptedAnswerId FROM Posts WHERE Id = ps.PostId
    ) OR ps.PostId IN (
        SELECT ParentId FROM Posts WHERE Id = ps.PostId
    )
WHERE 
    psh.Level < 3
ORDER BY 
    ps.VoteCount DESC, ps.CommentCount DESC;
