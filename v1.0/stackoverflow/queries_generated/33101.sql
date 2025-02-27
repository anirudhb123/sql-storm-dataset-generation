WITH RecursivePostHierarchy AS (
    -- Base case: Select top-level questions
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        1 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1

    UNION ALL

    -- Recursive case: Select answers and link them to their questions
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        Level + 1
    FROM
        Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
)

SELECT
    ph.PostId,
    ph.Title,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    COUNT(c.Id) AS CommentCount,
    AVG(vote.Score) AS AverageScore,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COUNT(DISTINCT tags.TagName) AS TagCount,
    ROW_NUMBER() OVER (PARTITION BY ph.OwnerUserId ORDER BY ph.Level DESC) AS UserPostRank
FROM
    RecursivePostHierarchy ph
LEFT JOIN
    Users u ON ph.OwnerUserId = u.Id
LEFT JOIN
    Comments c ON ph.PostId = c.PostId
LEFT JOIN
    Votes vote ON ph.PostId = vote.PostId AND vote.VoteTypeId = 2 -- Counting only UpVotes
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON u.Id = b.UserId
LEFT JOIN (
    SELECT 
        p.Id AS PostId,
        string_agg(t.TagName, ', ') AS TagName
    FROM 
        Posts p
    INNER JOIN 
        unnest(string_to_array(p.Tags, ',')) AS tag ON TRUE
    INNER JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
) tags ON ph.PostId = tags.PostId
WHERE
    ph.Level = 1 -- Filter for only top-level questions
GROUP BY
    ph.PostId, ph.Title, u.DisplayName, u.Reputation, b.BadgeCount
ORDER BY
    AverageScore DESC, CommentCount DESC;
