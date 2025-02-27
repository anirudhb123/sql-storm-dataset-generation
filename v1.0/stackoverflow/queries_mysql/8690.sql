
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostRanking AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        (@row_number:=IF(@current_user = p.OwnerUserId, @row_number + 1, 1)) AS Rank,
        @current_user := p.OwnerUserId
    FROM 
        Posts p,
        (SELECT @row_number := 0, @current_user := NULL) AS rn
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        p.OwnerUserId, p.Score DESC
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.AnswerCount,
    us.AcceptedAnswers,
    us.CommentCount,
    us.TotalBadges,
    pr.PostId,
    pr.Title,
    pr.Score,
    pr.ViewCount,
    pr.CreationDate
FROM 
    UserStats us
JOIN 
    PostRanking pr ON us.UserId = pr.OwnerUserId
WHERE 
    pr.Rank <= 5
ORDER BY 
    us.Reputation DESC, 
    pr.Score DESC;
