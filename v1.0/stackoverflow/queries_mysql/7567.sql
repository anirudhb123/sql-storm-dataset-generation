
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostsCount,
        ua.Upvotes,
        ua.Downvotes,
        @rank := @rank + 1 AS Rank
    FROM 
        UserActivity ua, (SELECT @rank := 0) r
    WHERE 
        ua.PostsCount > 0
    ORDER BY 
        ua.PostsCount DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    rp.AnswerCount,
    rp.LastEditDate,
    tau.UserId,
    tau.DisplayName AS TopPoster,
    tau.PostsCount,
    tau.Upvotes,
    tau.Downvotes
FROM 
    RecentPosts rp
LEFT JOIN 
    TopActiveUsers tau ON tau.Rank = 1
ORDER BY 
    rp.ViewCount DESC
LIMIT 10;
