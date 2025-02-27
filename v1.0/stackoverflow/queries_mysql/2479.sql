
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS Ranking,
        @current_user := p.OwnerUserId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId,
        (SELECT @row_number := 0, @current_user := NULL) AS init
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Upvotes,
    us.Downvotes,
    us.PostCount,
    us.CommentCount,
    us.BadgeCount,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.Ranking,
    pd.TotalComments
FROM 
    UserStats us
LEFT JOIN 
    PostDetails pd ON us.UserId = pd.PostId
WHERE 
    us.Upvotes > us.Downvotes
    AND us.PostCount > 5
    AND EXISTS (
        SELECT 1
        FROM Badges b
        WHERE b.UserId = us.UserId AND b.Class = 1
    )
ORDER BY 
    us.Upvotes DESC, us.PostCount DESC, us.BadgeCount DESC
LIMIT 100;
