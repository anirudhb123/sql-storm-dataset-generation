
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        @row_num := IF(@current_user = p.OwnerUserId, @row_num + 1, 1) AS PostRank,
        @current_user := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId,
        (SELECT @row_num := 0, @current_user := NULL) AS init
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(IFNULL(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPerformers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalScore,
        us.TotalViews,
        us.TotalBadges,
        @ranking := @ranking + 1 AS Ranking
    FROM 
        UserScores us,
        (SELECT @ranking := 0) AS init
    ORDER BY 
        us.TotalScore DESC, us.TotalViews DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.AnswerCount,
    tp.DisplayName AS TopUser,
    tp.TotalScore
FROM 
    RankedPosts rp
JOIN 
    TopPerformers tp ON rp.PostRank = 1
WHERE 
    tp.Ranking <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
