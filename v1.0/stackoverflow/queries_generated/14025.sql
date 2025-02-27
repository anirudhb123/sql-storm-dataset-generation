-- Performance benchmarking query for Stack Overflow schema
WITH PostCounts AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore,
        AVG(AnswerCount) AS AvgAnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000 -- considering only users with reputation greater than 1000
    GROUP BY 
        p.PostTypeId
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        BadgeCounts bc ON u.Id = bc.UserId
    GROUP BY 
        u.Id
)
SELECT 
    pc.PostTypeId,
    pc.PostCount,
    pc.AvgViewCount,
    pc.AvgScore,
    pc.AvgAnswerCount,
    ua.UserId,
    ua.PostCount AS UserPostCount,
    ua.CommentCount AS UserCommentCount,
    ua.BadgeCount
FROM 
    PostCounts pc
JOIN 
    UserActivity ua ON ua.PostCount > 0
ORDER BY 
    pc.PostTypeId, ua.BadgeCount DESC;
