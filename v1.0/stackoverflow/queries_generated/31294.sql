WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        0 AS Level,
        1 AS PathCount
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
        ph.Level + 1,
        ph.PathCount + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
PostStats AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        MAX(case when v.VoteTypeId = 1 then 1 else 0 end) AS Accepted
    FROM 
        PostHierarchy ph
    LEFT JOIN 
        Comments c ON ph.PostId = c.PostId
    LEFT JOIN 
        Votes v ON ph.PostId = v.PostId
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalReputation DESC
    LIMIT 10
)
SELECT 
    ph.PostId,
    ph.Title,
    u.DisplayName AS PostOwner,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    CASE 
        WHEN ps.Accepted = 1 THEN 'Accepted' 
        ELSE 'Not Accepted' 
    END AS AnswerStatus,
    json_agg(DISTINCT t.TagName) AS AssociatedTags
FROM 
    PostHierarchy ph
LEFT JOIN 
    Posts p ON ph.PostId = p.Id
LEFT JOIN 
    PostStats ps ON ph.PostId = ps.PostId
LEFT JOIN 
    Tags t ON t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>'))::int) WHERE p.PostTypeId = 1)
LEFT JOIN 
    Users u ON ph.OwnerUserId = u.Id
WHERE 
    ps.CommentCount > 5
GROUP BY 
    ph.PostId, u.DisplayName
ORDER BY 
    ps.UpvoteCount DESC, ps.CommentCount DESC;
