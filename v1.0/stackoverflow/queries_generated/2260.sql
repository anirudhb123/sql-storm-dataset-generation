WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentActivity AS (
    SELECT 
        UserId,
        MAX(CreationDate) AS LastActivity
    FROM 
        Comments
    GROUP BY 
        UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.QuestionCount,
    us.Upvotes,
    us.Downvotes,
    us.CommentCount,
    us.BadgeCount,
    ra.LastActivity,
    rp.Title AS TopQuestionTitle,
    rp.CreationDate AS TopQuestionDate
FROM 
    UserStats us
LEFT JOIN 
    RecentActivity ra ON us.UserId = ra.UserId
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    us.QuestionCount > 0
ORDER BY 
    us.Upvotes DESC, us.QuestionCount DESC
FETCH FIRST 10 ROWS ONLY;
