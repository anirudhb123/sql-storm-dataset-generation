
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(year, -1, CURRENT_DATE())
),

UserActivity AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.DisplayName, u.Reputation
),

TopActiveUsers AS (
    SELECT 
        ua.DisplayName,
        ua.Reputation,
        ua.QuestionCount,
        ua.TotalViews,
        ua.TotalComments,
        ua.TotalScore,
        DENSE_RANK() OVER (ORDER BY ua.TotalViews DESC) AS RankByViews
    FROM 
        UserActivity ua
    WHERE 
        ua.QuestionCount > 0
)

SELECT 
    t.DisplayName,
    t.Reputation,
    t.QuestionCount,
    t.TotalViews,
    t.TotalComments,
    t.TotalScore,
    rp.Title AS LatestPostTitle,
    rp.CreationDate AS LatestPostDate
FROM 
    TopActiveUsers t
LEFT JOIN 
    (
        SELECT 
            rp.Title,
            rp.CreationDate,
            rp.OwnerUserId
        FROM 
            RankedPosts rp
        WHERE 
            rp.rn = 1
    ) rp ON t.DisplayName = (SELECT u.DisplayName FROM Users u WHERE u.Id = rp.OwnerUserId)
WHERE 
    t.RankByViews <= 10 
ORDER BY 
    t.TotalViews DESC, 
    t.TotalScore DESC;
