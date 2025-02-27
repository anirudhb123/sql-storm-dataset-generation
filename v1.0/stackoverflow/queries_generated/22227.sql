WITH RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN p.CreationDate > NOW() - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentPosts,
        SUM(CASE WHEN c.CreationDate > NOW() - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        json_agg(
            json_build_object(
                'HistoryType', pht.Name,
                'CreationDate', ph.CreationDate,
                'Comment', ph.Comment
            )
        ) AS HistoryDetails
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ra.PostCount, 0) AS TotalPosts,
    COALESCE(ra.CommentCount, 0) AS TotalComments,
    COALESCE(ra.RecentPosts, 0) AS RecentPosts,
    COALESCE(ra.RecentComments, 0) AS RecentComments,
    COALESCE(b.BadgeCount, 0) AS TotalBadges,
    COALESCE(b.BadgeNames, 'No badges') AS BadgeDetails,
    (
        SELECT 
            json_agg(post_summary)
        FROM 
            (
                SELECT 
                    p.Id AS PostId,
                    p.Title,
                    p.CreationDate,
                    p.Score,
                    COALESCE(p.AnswerCount, 0) AS AnswerCount,
                    hs.HistoryDetails
                FROM 
                    Posts p
                LEFT JOIN 
                    PostHistorySummary hs ON p.Id = hs.PostId
                WHERE 
                    p.OwnerUserId = u.Id
                ORDER BY 
                    p.CreationDate DESC
                LIMIT 5
            ) AS post_summary
    ) AS RecentPostsDetails
FROM 
    Users u
LEFT JOIN 
    RecentUserActivity ra ON u.Id = ra.UserId
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 1000  -- Filtering for users with a reputation greater than 1000
ORDER BY 
    u.DisplayName
LIMIT 10;
