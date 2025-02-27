WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        ParentId,
        0 AS Level,
        Title,
        CreationDate,
        OwnerUserId,
        Score
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        Level + 1,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(vtt.Score, 0)) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes vtt ON p.Id = vtt.PostId AND vtt.VoteTypeId IN (2, 3) -- Upvotes and downvotes
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteAggregation AS (
    SELECT 
        p.Id,
        COUNT(v.Id) AS VoteCount,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.CreationDate,
    us.DisplayName AS OwnerUser,
    us.BadgeCount,
    us.TotalVotes,
    pv.VoteCount,
    pv.AverageBounty,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    RecursivePostHierarchy ph
JOIN 
    Users us ON ph.OwnerUserId = us.Id
LEFT JOIN 
    PostVoteAggregation pv ON ph.PostId = pv.Id
LEFT JOIN 
    STRING_TO_ARRAY(SUBSTRING(ph.Tags, 2, LENGTH(ph.Tags) - 2), '><') AS tag_array ON true
LEFT JOIN 
    Tags t ON t.TagName = tag_array
GROUP BY 
    ph.PostId, us.DisplayName, pv.VoteCount, pv.AverageBounty, ph.Title, ph.CreationDate
ORDER BY 
    ph.CreationDate DESC, pv.VoteCount DESC
LIMIT 100;
