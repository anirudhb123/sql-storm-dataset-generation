WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
        AND p.Score > 0
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),
ClosedPosts AS (
    SELECT 
        PostId,
        MAX(CreationDate) AS LastClosedDate
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId = 10
    GROUP BY 
        PostId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(up.BadgeCount, 0) AS BadgeCount,
        COALESCE(cp.LastClosedDate, 'No Closed Posts') AS LastClosedPost,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        SUM(rp.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadges up ON u.Id = up.UserId
    LEFT JOIN 
        ClosedPosts cp ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, up.BadgeCount, cp.LastClosedDate
    HAVING 
        COUNT(DISTINCT rp.PostId) > 10
)
SELECT 
    t.DisplayName,
    t.BadgeCount,
    t.TotalPosts,
    t.TotalScore,
    CASE 
        WHEN t.BadgeCount > 5 THEN 'Expert'
        WHEN t.TotalScore > 1000 THEN 'Veteran'
        ELSE 'Newbie'
    END AS UserLevel,
    CASE 
        WHEN t.LastClosedPost = 'No Closed Posts' THEN NULL
        ELSE t.LastClosedPost
    END AS LastClosedPost
FROM 
    TopUsers t
ORDER BY 
    t.TotalScore DESC, 
    t.TotalPosts DESC;

This SQL query performs several advanced operations:
1. Generates a ranking of posts by users along with their associated data.
2. Counts and aggregates user badges.
3. Gets the latest closed post date for each user.
4. Combines all this information into a summary that also classifies users based on their activity and achievements.
5. Applies NULL logic to handle users with no closed posts. 

It shows the power of combining window functions, common table expressions (CTEs), joins, and conditional logic in SQL.
