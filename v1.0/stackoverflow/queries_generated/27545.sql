WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 -- Only the latest post per user
        AND rp.Score > 0 -- Only consider posts with a positive score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(rp.Score) AS TotalScore,
        COUNT(DISTINCT rp.PostId) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        FilteredPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        TotalPosts > 0 -- Users with at least one post
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalBadges,
    us.TotalViews,
    us.TotalScore,
    us.TotalPosts,
    STRING_AGG(DISTINCT rp.Title, '; ') AS RecentPostTitles
FROM 
    UserStats us
JOIN 
    FilteredPosts rp ON us.UserId = rp.OwnerUserId
GROUP BY 
    us.UserId, us.DisplayName, us.TotalBadges, us.TotalViews, us.TotalScore, us.TotalPosts
ORDER BY 
    us.TotalScore DESC, us.TotalViews DESC;
