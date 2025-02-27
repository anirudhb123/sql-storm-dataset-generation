WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        0 AS Level,
        CAST(p.Title AS varchar(max)) AS Path
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        ph.Level + 1,
        CAST(ph.Path + ' -> ' + p.Title AS varchar(max))
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.Score,
        COALESCE(pc.ClosedPostCount, 0) AS ClosedPostCount,
        COALESCE(ac.AcceptedAnswerCount, 0) AS AcceptedAnswerCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreatedDate DESC) AS RowNumber
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            p.Id,
            COUNT(DISTINCT ph.PostId) AS ClosedPostCount
        FROM 
            Posts p
        LEFT JOIN 
            PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
        GROUP BY 
            p.Id
    ) pc ON p.Id = pc.Id
    LEFT JOIN (
        SELECT 
            p.ParentId,
            COUNT(DISTINCT p.Id) AS AcceptedAnswerCount
        FROM 
            Posts p
        WHERE 
            p.AcceptedAnswerId IS NOT NULL
        GROUP BY 
            p.ParentId
    ) ac ON p.Id = ac.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.Score
)
SELECT 
    u.DisplayName,
    us.VoteCount,
    us.UpVotes,
    us.DownVotes,
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ClosedPostCount,
    ps.AcceptedAnswerCount,
    ps.CommentCount,
    ph.Path,
    ps.RowNumber
FROM 
    Users u
JOIN 
    UserVoteSummary us ON u.Id = us.UserId
JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    PostHierarchy ph ON ps.PostId = ph.PostId
WHERE 
    us.VoteCount > 0
    AND ps.Score >= 5
ORDER BY 
    us.VoteCount DESC, ps.Score DESC;
