WITH RECURSIVE PostHierarchy AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        1 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- Start from questions

    UNION ALL

    SELECT
        p2.Id,
        p2.Title,
        p2.OwnerUserId,
        p2.CreationDate,
        ph.Level + 1
    FROM
        Posts p2
    JOIN
        Posts p ON p2.ParentId = p.Id
    JOIN
        PostHierarchy ph ON ph.PostId = p.Id
)
SELECT
    ph.PostId,
    ph.Title,
    ph.Level,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    AVG(v.BountyAmount) AS AverageBounty,
    ROW_NUMBER() OVER (PARTITION BY ph.OwnerUserId ORDER BY ph.CreationDate DESC) AS PostRank,
    MAX(CASE WHEN p.ClosedDate IS NOT NULL THEN 'Closed' ELSE 'Open' END) AS PostStatus,
    STRING_AGG(pt.Name, ', ') FILTER (WHERE pt.Name IS NOT NULL) AS PostType,
    COUNT(DISTINCT ph2.PostId) AS LinkedPosts
FROM
    PostHierarchy ph
LEFT JOIN
    Users u ON ph.OwnerUserId = u.Id
LEFT JOIN
    Comments c ON c.PostId = ph.PostId
LEFT JOIN
    Votes v ON v.PostId = ph.PostId AND v.VoteTypeId IN (8, 9)  -- Bounty Start or Close
LEFT JOIN
    PostLinks pl ON pl.PostId = ph.PostId
LEFT JOIN
    Posts ph2 ON pl.RelatedPostId = ph2.Id
LEFT JOIN
    PostTypes pt ON ph.PostId = pt.Id
GROUP BY
    ph.PostId, ph.Title, ph.OwnerUserId, u.DisplayName, u.Reputation, ph.Level
HAVING
    COUNT(c.Id) > 5 OR AVG(v.BountyAmount) > 0
ORDER BY
    OwnerReputation DESC, PostRank, Level;
