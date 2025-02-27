WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn,
        STRING_AGG(t.TagName, ', ') FILTER (WHERE t.TagName IS NOT NULL) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id OR t.WikiPostId = p.Id
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score, p.PostTypeId
),
PostStatistics AS (
    SELECT 
        p.UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.UserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.CreationDate > CURRENT_DATE - INTERVAL '2 years'
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    COALESCE(up.TotalPosts, 0) AS TotalPosts,
    COALESCE(up.TotalBounties, 0) AS TotalBounties,
    COALESCE(up.TotalUpvotes, 0) AS TotalUpvotes,
    COALESCE(up.TotalDownvotes, 0) AS TotalDownvotes,
    ub.BadgeCount,
    ub.BadgeNames,
    CASE 
        WHEN up.TotalPosts > 50 THEN 'High Contributor'
        WHEN up.TotalPosts > 20 THEN 'Medium Contributor'
        ELSE 'Low Contributor'
    END AS ContributorStatus,
    STRING_AGG(rp.Title || ' (Views: ' || rp.ViewCount || ', Score: ' || rp.Score || ', Tags: ' || rp.Tags || ')', '; ') AS RecentPosts
FROM 
    PostStatistics up
FULL OUTER JOIN 
    UserBadges ub ON up.UserId = ub.UserId
LEFT JOIN 
    RankedPosts rp ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId LIMIT 1)
GROUP BY 
    up.UserId, ub.BadgeCount, ub.BadgeNames
ORDER BY 
    ContributorStatus DESC NULLS LAST, TotalPosts DESC;
