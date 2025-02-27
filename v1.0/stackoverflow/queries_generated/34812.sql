WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score > 0
),

PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),

PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(CASE 
            WHEN ph.PostHistoryTypeId IN (4, 5) THEN ph.Comment 
            ELSE NULL 
        END, ', ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
    GROUP BY 
        ph.PostId
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(sub.BadgeCount, 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        UserBadges sub ON u.Id = sub.UserId
    GROUP BY 
        u.Id
)

SELECT 
    up.PostId,
    up.Title,
    up.CreationDate,
    up.ViewCount,
    pv.Upvotes,
    pv.Downvotes,
    ph.EditCount,
    ph.LastEditDate,
    u.DisplayName AS PostOwner,
    ua.TotalViews AS OwnerTotalViews,
    ua.TotalBadges AS OwnerBadgeCount
FROM 
    RankedPosts up
LEFT JOIN 
    PostVoteSummary pv ON up.PostId = pv.PostId
LEFT JOIN 
    PostHistoryAggregates ph ON up.PostId = ph.PostId
JOIN 
    Users u ON up.OwnerUserId = u.Id
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
WHERE 
    up.Rank <= 5
ORDER BY 
    up.Score DESC;

This SQL query does the following:

1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Ranks posts over the last year by score within their post types.
   - `PostVoteSummary`: Summarizes upvotes and downvotes for each post.
   - `PostHistoryAggregates`: Aggregates edit counts and comments from post histories.
   - `UserBadges`: Counts badges for users and aggregates their names.
   - `UserActivity`: Summarizes views and badges for each user based on their posts.

2. **Main Query**: Combines results from CTEs to select key post details along with the summary of votes, edits, and post owner's information, limiting results to the top 5 posts per type by score.

3. **Complicated Logic**:
   - Uses window functions for ranking posts.
   - Implements aggregation with conditions.
   - Includes outer joins to ensure all post owners are included even if they have no associated votes or badges. 

4. **Final Output**: This displays the most relevant information for posts while aggregating data about user activity.
