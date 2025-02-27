WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        COALESCE(ph.PostHistoryTypeId, 0) AS LastActionType,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate = (
            SELECT MAX(CreationDate)
            FROM PostHistory ph2
            WHERE ph2.PostId = p.Id
        )
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.AnswerCount, ph.PostHistoryTypeId
),

UserRank AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.UpVotes,
        ua.DownVotes,
        ua.CommentCount,
        ROW_NUMBER() OVER (ORDER BY ua.UpVotes DESC, ua.PostCount DESC) AS UserRank
    FROM 
        UserActivity ua
)

SELECT 
    ur.DisplayName AS TopUser,
    ur.UpVotes,
    ur.CommentCount,
    ps.Title AS RecentPostTitle,
    ps.CreationDate AS RecentPostDate,
    ps.Score AS PostScore,
    ps.TotalComments AS CommentCount,
    ps.LastActionType AS LastAction,
    ps.PostRank AS UserPostRank
FROM 
    UserRank ur
LEFT JOIN 
    PostStats ps ON ur.UserId = ps.OwnerUserId
WHERE 
    ur.UserRank <= 10
    AND (ps.CreationDate >= CURRENT_DATE - INTERVAL '30 days' OR ps.LastActionType = 10)
ORDER BY 
    ur.UpVotes DESC, ps.CreationDate DESC;

This query combines multiple SQL features including Common Table Expressions (CTEs), window functions, LEFT JOINs, COALESCE, and intricate conditions. It aims to retrieve top user activity, along with their posts and relevant statistics within the last 30 days or based on the last action type. It also explores a situation where users with upvotes and comments are prioritized in ranking, ensuring edge cases with optional filtering are encompassed.
