WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
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
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostMetrics AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS LatestPostNumber,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
PostSummary AS (
    SELECT 
        pm.Title,
        pm.CommentCount,
        pm.VoteCount,
        pm.UpVotes,
        pm.DownVotes,
        u.Reputation,
        u.DisplayName,
        (SELECT COUNT(DISTINCT Id) FROM RecursivePostHierarchy r WHERE r.PostId = pm.Id) AS AnswerCount
    FROM 
        PostMetrics pm
    JOIN 
        Users u ON pm.OwnerUserId = u.Id
)
SELECT 
    ps.Title,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.Reputation,
    ps.DisplayName,
    CASE 
        WHEN ps.AnswerCount > 0 THEN CONCAT(ps.AnswerCount, ' answers')
        ELSE 'No answers yet'
    END AS AnswerStatus,
    COALESCE(CONVERT(VARCHAR, DATEDIFF(DAY, ps.LatestPostDate, GETDATE())), 'N/A') AS DaysSinceLastPost
FROM 
    PostSummary ps
WHERE 
    ps.Reputation > 100
ORDER BY 
    ps.CommentCount DESC, ps.UpVotes DESC;
