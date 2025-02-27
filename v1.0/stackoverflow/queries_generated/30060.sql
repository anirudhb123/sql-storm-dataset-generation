WITH RecursiveUserHierarchy AS (
    SELECT 
        Id, 
        Reputation,
        CreationDate,
        DisplayName,
        CAST(NULL AS INT) AS ParentId
    FROM 
        Users
    WHERE 
        Reputation > 1000  -- First layer: users with high reputation

    UNION ALL

    SELECT 
        u.Id, 
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u2.Id 
    FROM 
        Users u
    INNER JOIN 
        RecursiveUserHierarchy u2 ON u.Reputation < u2.Reputation / 2  -- Next layers: users with lower reputation
    WHERE 
        u2.Reputation > 1000
),

PostVoteCounts AS (
    SELECT
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
),

UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '>')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id
),

LatestComments AS (
    SELECT 
        PostId,
        Text AS LatestComment
    FROM 
        Comments c
    WHERE 
        CreationDate = (SELECT MAX(CreationDate) FROM Comments WHERE PostId = c.PostId)
)

SELECT 
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    u.CreationDate,
    ub.BadgeCount,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COALESCE(SUM(pvc.Upvotes - pvc.Downvotes), 0) AS NetVotes,
    STRING_AGG(DISTINCT pt.Tags, '; ') AS AssociatedTags,
    lc.LatestComment
FROM 
    Users u
LEFT JOIN 
    PostVoteCounts pvc ON u.Id = p.OwnerUserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostTags pt ON p.Id = pt.PostId
LEFT JOIN 
    LatestComments lc ON p.Id = lc.PostId
WHERE 
    u.Reputation > 1000 AND 
    (uc.ParentId IS NULL OR uc.ParentId = 0)  -- Filter for top-level users only in hierarchy
GROUP BY 
    u.Id, ub.BadgeCount, lc.LatestComment
ORDER BY 
    u.Reputation DESC
LIMIT 100;
