WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation AS UserReputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UniqueUpVotes,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS UniqueDownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.PostTypeId,
        ps.CommentCount,
        ps.TotalBounty,
        ps.UniqueUpVotes,
        ps.UniqueDownVotes,
        ur.UserReputation,
        ur.ReputationRank
    FROM 
        PostStatistics ps
    JOIN 
        Users u ON u.Id = (
            SELECT OwnerUserId 
            FROM Posts 
            WHERE Id = ps.PostId
        )
    JOIN 
        UserReputation ur ON u.Id = ur.UserId
    WHERE 
        ps.PostRank <= 10
),
ConcernedPosts AS (
    SELECT 
        tp.PostId,
        tp.PostTypeId,
        tp.CommentCount,
        tp.TotalBounty,
        tp.UniqueUpVotes,
        tp.UniqueDownVotes,
        tp.UserReputation,
        tp.ReputationRank,
        CASE 
            WHEN tp.TotalBounty > 0 THEN 'Has Bounty'
            ELSE 'No Bounty'
        END AS BountyStatus
    FROM 
        TopPosts tp 
    WHERE 
        (tp.CommentCount > 5 OR tp.UniqueUpVotes >= 10)
)

SELECT 
    cp.PostId,
    p.Title,
    COUNT(c.Id) AS TotalComments,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    cp.UserReputation,
    cp.ReputationRank,
    cp.BountyStatus,
    (SELECT Name FROM PostTypes WHERE Id = cp.PostTypeId) AS PostType
FROM 
    ConcernedPosts cp
JOIN 
    Posts p ON cp.PostId = p.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    cp.PostId, p.Title, cp.UserReputation, cp.ReputationRank, cp.BountyStatus
ORDER BY 
    cp.UserReputation DESC, TotalComments DESC;

WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.ParentId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
)
SELECT 
    ph.Id,
    COUNT(p.Id) AS AnswerCount
FROM 
    PostHierarchy ph
LEFT JOIN 
    Posts p ON ph.Id = p.ParentId
WHERE 
    p.PostTypeId = 2 -- Only answers
GROUP BY 
    ph.Id
HAVING 
    COUNT(p.Id) > 0
ORDER BY 
    AnswerCount DESC;

-- Observing the strange results from LEFT JOIN with NULL checks
SELECT 
    p.Id AS PostId,
    COALESCE(c.Text, 'No comments yet') AS CommentText,
    CASE 
        WHEN c.CreationDate IS NULL THEN 'No recent comments'
        ELSE 'Recent comments exist'
    END AS CommentStatus
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId AND c.CreationDate >= NOW() - INTERVAL '3 days'
WHERE 
    p.PostTypeId IN (1, 2) 
ORDER BY 
    p.CreationDate DESC
LIMIT 5;

-- Using UNIONS to combine results of different query types
SELECT 
    u.DisplayName, 
    COUNT(p.Id) AS TotalPosts,
    ROW_NUMBER() OVER (ORDER BY COUNT(p
