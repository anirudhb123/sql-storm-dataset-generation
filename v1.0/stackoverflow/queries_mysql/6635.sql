
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        p.OwnerUserId AS UserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PostStats AS (
    SELECT 
        p.OwnerUserId AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(UNIX_TIMESTAMP(p.CreationDate)) AS AveragePostDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.OwnerUserId, u.DisplayName
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.AnswerCount,
    r.CommentCount,
    r.FavoriteCount,
    ps.DisplayName AS Author,
    ps.TotalPosts,
    ps.TotalScore,
    ps.TotalViews,
    FROM_UNIXTIME(ps.AveragePostDate) AS AveragePostDate
FROM 
    RankedPosts r
JOIN 
    PostStats ps ON r.UserId = ps.UserId
WHERE 
    r.Rank <= 10
ORDER BY 
    r.PostId, r.Score DESC;
