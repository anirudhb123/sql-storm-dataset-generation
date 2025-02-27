WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        cte.Level + 1
    FROM 
        RecursiveCTE cte
    JOIN 
        Posts p ON p.ParentId = cte.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        STRING_AGG(t.TagName, ', ') AS Tags,
        p.Score,
        p.CreationDate,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tagName ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tagName
    GROUP BY 
        p.Id
)
SELECT 
    p.Title,
    p.Score,
    p.CommentCount,
    u.DisplayName AS OwnerName,
    us.Reputation,
    us.UpVotes,
    us.DownVotes,
    pt.Tags,
    CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Yes' ELSE 'No' END AS HasAcceptedAnswer,
    CASE 
        WHEN p.CreationDate < CURRENT_DATE - INTERVAL '1 year' THEN 'Old' 
        ELSE 'Recent' 
    END AS PostAge,
    ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    PostWithTags pt ON p.Id = pt.PostId
WHERE 
    p.PostTypeId = 1 -- Only questions
    AND p.Score > 0
    AND pt.Tags LIKE '%SQL%' -- Example predicate for filtering tags
ORDER BY 
    p.Score DESC
LIMIT 100;

-- Include Result Set Information
EXPLAIN ANALYZE 
WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level 
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        cte.Level + 1 
    FROM 
        RecursiveCTE cte 
    JOIN 
        Posts p ON p.ParentId = cte.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount 
    FROM 
        Users u 
    LEFT JOIN 
        Votes v ON u.Id = v.UserId 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id
),
PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        STRING_AGG(t.TagName, ', ') AS Tags
