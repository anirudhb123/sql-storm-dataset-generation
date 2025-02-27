WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, u.DisplayName, p.PostTypeId
),
TopRatedPosts AS (
    SELECT 
        PostId, Title, ScoreRank, ViewCount, OwnerDisplayName, CreationDate
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 5
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    trp.Title AS TopPostTitle,
    trp.ViewCount AS TopPostViews,
    trp.CreationDate AS TopPostDate,
    trp.OwnerDisplayName AS TopPostOwner,
    ub.BadgeCount AS OwnerBadgeCount,
    ub.BadgeNames AS OwnerBadgeNames
FROM 
    TopRatedPosts trp
LEFT JOIN 
    UserBadges ub ON trp.OwnerDisplayName = ub.UserId
ORDER BY 
    trp.ViewCount DESC
LIMIT 10;

-- This query retrieves the top 5 rated posts of the last year,
-- along with the corresponding owner's badge counts and names,
-- ordered by the highest view counts, giving insights into
-- popular content and the expertise of its creators.
