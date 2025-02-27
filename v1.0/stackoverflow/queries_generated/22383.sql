WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostsWithBadges AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        ARRAY_AGG(DISTINCT b.Name) AS BadgeNames
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        ud.DisplayName,
        ud.Reputation,
        pwb.BadgeNames,
        CASE 
            WHEN rp.Score > 10 THEN 'High Score'
            WHEN rp.Score BETWEEN 5 AND 10 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserDetails ud ON rp.OwnerUserId = ud.UserId
    LEFT JOIN 
        PostsWithBadges pwb ON rp.PostId = pwb.Id
    WHERE 
        rp.PostRank = 1 AND ud.Reputation > 100
)
SELECT 
    f.Title,
    f.DisplayName,
    f.Reputation,
    f.Score,
    f.ViewCount,
    f.BadgeNames,
    COALESCE((
        SELECT COUNT(*) 
        FROM Comments c 
        WHERE c.PostId = f.PostId
    ), 0) AS CommentCount,
    CASE 
        WHEN f.ViewCount IS NULL THEN 'No Views'
        ELSE 'Views Recorded'
    END AS ViewStatus
FROM 
    FilteredPosts f
ORDER BY 
    f.Score DESC,
    f.ViewCount DESC;

WITH recent_closed_posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ClosedDate,
        STRING_AGG(pt.Name, ', ') AS CloseReasons,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        CloseReasonTypes pt ON ph.Comment::int = pt.Id
    WHERE 
        p.ClosedDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.ClosedDate
)
SELECT 
    'Closed Posts Recently' AS Category,
    PostId,
    Title,
    ClosedDate,
    CloseReasons,
    CommentCount
FROM 
    recent_closed_posts
WHERE 
    CommentCount > 0
ORDER BY 
    ClosedDate DESC;

WITH unique_tags AS (
    SELECT 
        DISTINCT UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS Tag
    FROM 
        Posts p
)
SELECT 
    ut.Tag,
    COUNT(*) AS PostCount,
    SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostsOwned,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyCollected
FROM 
    unique_tags ut
LEFT JOIN 
    Posts p ON p.Tags LIKE '%' || ut.Tag || '%'
LEFT JOIN 
    Votes v ON v.PostId = p.Id
GROUP BY 
    ut.Tag
HAVING 
    COUNT(*) > 1 -- More than one post for the tag
ORDER BY 
    PostCount DESC;
