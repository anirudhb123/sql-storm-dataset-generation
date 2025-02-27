WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT r.PostId) AS PostsCreated,
        SUM(r.Score) AS TotalScore,
        SUM(r.AnswerCount) AS TotalAnswers,
        SUM(r.CommentCount) AS TotalComments
    FROM 
        Users u
    JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    WHERE 
        r.Rank <= 10
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostsCreated,
    u.TotalScore,
    u.TotalAnswers,
    u.TotalComments,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    b.Class AS BadgeClass
FROM 
    TopUsers u
LEFT JOIN 
    Badges b ON u.UserId = b.UserId AND b.Date >= NOW() - INTERVAL '1 year'
ORDER BY 
    u.TotalScore DESC, u.PostsCreated DESC
LIMIT 20;
