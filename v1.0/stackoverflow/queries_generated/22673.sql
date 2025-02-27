WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankWithinType,
        SUM(p.Score) OVER (PARTITION BY p.OwnerUserId) AS TotalOwnerScore,
        ARRAY_AGG(t.TagName) FILTER (WHERE t.TagName IS NOT NULL) AS PostTags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '><')) AS t(TagName) ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS BadgeCount, 
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        MAX(ph.CreationDate) AS LatestCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.UserDisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.RankWithinType,
    us.DisplayName AS OwnerDisplayName,
    us.BadgeCount,
    us.TotalBounty,
    us.MaxReputation,
    cp.LatestCloseDate,
    rp.PostTags
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserStatistics us ON u.Id = us.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.RankWithinType <= 3
ORDER BY 
    rp.Score DESC, 
    us.BadgeCount DESC 
FETCH FIRST 25 ROWS ONLY;

This SQL query does the following:

1. `RankedPosts` CTE: Ranks posts based on score, calculates the total score per user, and aggregates tags associated with the posts.
2. `UserStatistics` CTE: Summarizes badge counts, total bounties, and maximum reputation for each user.
3. `ClosedPosts` CTE: Gets the latest close date for each closed post.
4. The final selection joins these CTEs, filters for the top-ranked posts per type (up to 3), and fetches relevant user statistics and closure information.
5. The results are ordered by score and badge count, limiting results to the top 25 entries, representing an interesting combination of various SQL constructs and logical scenarios.
