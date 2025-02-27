WITH RECURSIVE UserTree AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        LastAccessDate,
        Location,
        CAST(1 AS INT) AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000 -- Start with users having more than 1000 reputation

    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Location,
        ut.Level + 1
    FROM 
        Users u
    JOIN 
        UserTree ut ON u.Id <> ut.Id AND u.Reputation < ut.Reputation -- Get users with lower reputation
)

SELECT 
    u.Id,
    u.DisplayName,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, -- Upvote count
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes, -- Downvote count
    COUNT(DISTINCT bh.Id) AS BadgeCount, -- Count of badges held
    COUNT(DISTINCT p.Id) AS PostCount, -- Count of posts made
    AVG(ut.Reputation) AS AvgReputation -- Average reputation in the tree
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId -- Left join with votes for counting
LEFT JOIN 
    Badges bh ON u.Id = bh.UserId -- Left join to count badges
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId -- Left join to count posts
LEFT JOIN 
    UserTree ut ON u.Id = ut.Id -- Join for hierarchical data
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    BadgeCount > 0 OR PostCount > 5 -- Condition for filtering results
ORDER BY 
    AvgReputation DESC, 
    UpVotes DESC;

-- Performance Benchmarking: including complicated predicates and expressions
SELECT 
    p.Id,
    p.Title,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(a.AcceptedAnswer, 'No Accepted Answer') AS AcceptedAnswer,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS Status,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT 
         Id AS AcceptedAnswer,
         ParentId 
     FROM 
         Posts 
     WHERE 
         PostTypeId = 2 AND AcceptedAnswerId IS NOT NULL) a 
ON 
    p.Id = a.ParentId
LEFT JOIN 
    Posts pp ON pp.Id = p.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            TagName 
        FROM 
            Tags t 
        WHERE 
            t.ExcerptPostId = p.Id
    ) AS t
GROUP BY 
    p.Id, p.Title, a.AcceptedAnswer, p.ClosedDate
ORDER BY 
    CASE 
        WHEN p.ViewCount > 1000 THEN 1
        ELSE 2
    END,
    p.CreationDate DESC;
