
WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END), 0) AS AcceptedAnswers,
        @Ranking := @Ranking + 1 AS Ranking
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @Ranking := 0) r
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostsDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ph.EditBody, 'N/A') AS LastEditedBody,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            MAX(CASE WHEN PostHistoryTypeId = 5 THEN Text END) AS EditBody
        FROM 
            PostHistory
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL 1 YEAR)
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Upvotes,
    us.Downvotes,
    ub.BadgeCount,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.AnswerCount,
    pd.CommentCount,
    pd.LastEditedBody
FROM 
    UserScores us
LEFT JOIN 
    UserBadges ub ON us.UserId = ub.UserId
LEFT JOIN 
    PostsDetails pd ON us.UserId = pd.OwnerUserId
WHERE 
    us.Ranking < 50
ORDER BY 
    us.Upvotes DESC, ub.BadgeCount DESC
LIMIT 20 OFFSET 10;
