WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        a.Score,
        a.CreationDate,
        rp.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE rp ON a.ParentId = rp.PostId
    WHERE 
        a.PostTypeId = 2  -- Answers only
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
AggregatedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        ua.TotalPosts,
        ua.TotalBounties,
        ROW_NUMBER() OVER (PARTITION BY rp.OwnerUserId ORDER BY rp.Score DESC) AS Rank
    FROM 
        RecursivePostCTE rp
    LEFT JOIN 
        UserActivity ua ON rp.OwnerUserId = ua.UserId
)
SELECT 
    ap.PostId,
    ap.Title,
    ap.Score,
    ap.CreationDate,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalBounties,
    COUNT(c.Id) AS CommentCount,
    MAX(pht.CreationDate) AS LatestEditDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    AggregatedPosts ap
LEFT JOIN 
    Users ua ON ap.OwnerUserId = ua.Id
LEFT JOIN 
    Comments c ON ap.PostId = c.PostId
LEFT JOIN 
    PostHistory pht ON ap.PostId = pht.PostId AND pht.PostHistoryTypeId IN (4, 5)  -- Edit Title, Edit Body
LEFT JOIN 
    Posts p ON ap.PostId = p.Id
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ', ') t ON p.Id = t.Id
WHERE 
    ap.Rank = 1  -- Only the highest score answer per user
GROUP BY 
    ap.PostId, ap.Title, ap.Score, ap.CreationDate, ua.DisplayName, ua.TotalPosts, ua.TotalBounties
ORDER BY 
    ap.Score DESC, ua.TotalPosts DESC
FETCH FIRST 100 ROWS ONLY;
