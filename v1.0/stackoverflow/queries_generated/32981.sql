WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) as UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users)
),
PostCommentStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    Posts.Title,
    p.OwnerDisplayName AS PostOwner,
    COALESCE(u.DisplayName, 'Anonymous') AS Commenter,
    pcs.CommentCount,
    pcs.UpVoteCount,
    pcs.DownVoteCount,
    RANK() OVER (PARTITION BY Posts.OwnerUserId ORDER BY pcs.UpVoteCount DESC) as UpVoteRank,
    (SELECT COUNT(*) 
     FROM PostHistory ph 
     WHERE ph.PostId = Posts.Id AND ph.PostHistoryTypeId = 10) AS CloseCount,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     WHERE t.Id IN (SELECT UNNEST(STRING_TO_ARRAY(Posts.Tags, ','))::int)) AS Tags
FROM 
    Posts
LEFT JOIN 
    Users u ON u.Id = Posts.OwnerUserId
JOIN 
    PostCommentStats pcs ON pcs.PostId = Posts.Id
LEFT JOIN 
    RecursivePostHierarchy rph ON rph.Id = Posts.Id
LEFT JOIN 
    TopUsers tu ON tu.Id = Posts.OwnerUserId
WHERE 
    COALESCE(Posts.ClosedDate, Current_Timestamp) > Current_Timestamp - INTERVAL '30 days'
    AND upVoteRank <= 5
ORDER BY 
    pcs.CommentCount DESC, 
    pcs.UpVoteCount DESC
LIMIT 50;
