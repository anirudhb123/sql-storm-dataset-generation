WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn,
        COALESCE(p.Title, 'Deleted Post') AS PostTitle
    FROM 
        PostHistory ph
    LEFT JOIN 
        Posts p ON ph.PostId = p.Id 
    WHERE 
        p.Id IS NOT NULL OR ph.PostHistoryTypeId IN (12, 13) -- Filtering for deleted/undeleted posts
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
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.Title,
        p.CreationDate,
        row_number() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 10 -- Filter posts with more than 10 score
)
SELECT 
    u.DisplayName,
    up.BadgeCount,
    up.BadgeNames,
    tp.PostTitle,
    tp.Score AS PostScore,
    ph.CreationDate AS HistoryDate,
    CASE 
        WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed'
        WHEN ph.PostHistoryTypeId IN (12, 13) THEN 'Deleted/Undeleted'
        ELSE 'Other Action'
    END AS PostAction,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
    CASE 
        WHEN (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) > 3
            THEN 'Highly Downvoted'
        ELSE 'Normal'
    END AS VoteStatus
FROM 
    Users u
JOIN 
    UserBadges up ON u.Id = up.UserId
JOIN 
    TopPosts tp ON u.Id = tp.PostId
LEFT JOIN 
    RecursivePostHistory ph ON tp.PostId = ph.PostId AND ph.rn = 1
WHERE 
    (ph.PostHistoryTypeId IS NOT NULL AND ph.PostHistoryTypeId != 66) 
    OR (up.BadgeCount > 2 AND ph.PostId IS NULL) -- No recent history but multiple badges
ORDER BY 
    Up.BadgeCount DESC, tp.Score DESC
LIMIT 50;
This SQL query does the following:

1. Uses a Common Table Expression (CTE) to recursively fetch post history while filtering out deleted/undeleted posts.
2. Computes badge counts and badge names for each user who has posts, aggregating their badge information.
3. Selects top posts based on score with a ranking.
4. Joins users, badge counts, top posts, and latest post history to find users with multiple badges and their associated top posts.
5. Utilizes COUNT and conditional logic in the SELECT statement to provide insights on comment counts, as well as a derived value based on votes.
6. Incorporates complex case statements to categorize actions taken on each post.
7. Applies multiple filters in the WHERE clause to retrieve meaningful data whilst also managing NULL values effectively.

This query presents a mixture of complex SQL constructs and ensures comprehensive results, showcasing users, their badges, and the corresponding post activities.
