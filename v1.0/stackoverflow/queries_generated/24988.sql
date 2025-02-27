WITH PostsStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        p.Score,
        p.ViewCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AnswerStatus,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b 
    GROUP BY 
        b.UserId
), RecentPosts AS (
    SELECT 
        ps.*,
        ub.BadgeNames,
        ub.BadgeCount
    FROM 
        PostsStats ps
    LEFT JOIN 
        UserBadges ub ON ps.PostId IN (
            SELECT 
                p.Id
            FROM 
                Posts p
            WHERE 
                p.OwnerUserId = ub.UserId
        )
    WHERE 
        ps.UserPostRank <= 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.PostType,
    rp.AnswerCount,
    rp.CommentCount,
    rp.Score,
    rp.ViewCount,
    rp.AnswerStatus,
    COALESCE(rp.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(rp.BadgeCount, 0) AS BadgeCount
FROM 
    RecentPosts rp
ORDER BY 
    rp.Score DESC,
    rp.ViewCount DESC
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;

-- Additional logic: mark posts with high views and low score as "Needs Attention"
SELECT 
    PostId,
    CASE 
        WHEN ViewCount > 1000 AND Score < 10 THEN 'Needs Attention' 
        ELSE 'Regular Post' 
    END AS AttentionStatus
FROM 
    Posts
WHERE 
    Score IS NOT NULL;

This elaborate query includes:

1. Common Table Expressions (CTEs) for organizing data:
    - `PostsStats`: gathers statistics about posts including their answer and comment counts, ranks posts by user.
    - `UserBadges`: summarizes badge information for users.
    - `RecentPosts`: combines the previous CTEs and filters to show recent posts only.

2. An advanced selection with multiple metrics such as `Score`, `ViewCount`, and badge information, displaying posts per user.

3. Joining subtables and using window functions for ranking and detailed metrics management.

4. An additional logic for tracking and identifying "Needs Attention" posts based on views and scores.

5. Usage of `STRING_AGG`, COALESCE for handling possible NULL values, and ordering to ensure the best posts are prioritized in the output.
