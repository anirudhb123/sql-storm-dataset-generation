-- Performance benchmarking query for Stack Overflow schema
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
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
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, p.FavoriteCount
),
Benchmark AS (
    SELECT 
        us.DisplayName,
        us.PostCount,
        us.TotalViews,
        us.TotalScore,
        us.BadgeCount,
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount AS PostViewCount,
        pd.Score AS PostScore,
        pd.AnswerCount,
        pd.CommentCount AS PostCommentCount,
        pd.FavoriteCount
    FROM 
        UserStats us
    JOIN 
        PostDetails pd ON us.UserId = pd.OwnerUserId
)
SELECT 
    DisplayName,
    PostCount,
    TotalViews,
    TotalScore,
    BadgeCount,
    Title,
    CreationDate,
    PostViewCount,
    PostScore,
    AnswerCount,
    PostCommentCount,
    FavoriteCount
FROM 
    Benchmark
ORDER BY 
    TotalScore DESC, TotalViews DESC
LIMIT 100;
