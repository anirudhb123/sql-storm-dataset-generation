WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.OwnerUserId,
        CAST(p.Title AS VARCHAR(MAX)) AS FullHierarchy
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        p2.OwnerUserId,
        CAST(r.FullHierarchy + ' -> ' + p2.Title AS VARCHAR(MAX))
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy r ON p2.ParentId = r.PostId
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        CONCAT(U.DisplayName, ' (', U.Reputation, ' points)') AS UserDisplay
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.ViewCount
)
SELECT 
    ph.PostId,
    ph.FullHierarchy,
    u.UserDisplay,
    pa.ViewCount,
    pa.CommentCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.LastVoteDate,
    (pa.UpVotes - pa.DownVotes) AS VoteBalance,
    CASE 
        WHEN pa.LastVoteDate IS NOT NULL THEN DATEDIFF(DAY, pa.LastVoteDate, GETDATE())
        ELSE NULL 
    END AS DaysSinceLastVote
FROM 
    RecursivePostHierarchy ph
JOIN 
    UserReputation u ON ph.OwnerUserId = u.UserId
JOIN 
    PostActivity pa ON ph.PostId = pa.PostId
WHERE 
    pa.ViewCount > 50 
    AND (pa.UpVotes - pa.DownVotes) > 5
ORDER BY 
    pa.ViewCount DESC, VoteBalance DESC
OPTION (MAXRECURSION 100);
