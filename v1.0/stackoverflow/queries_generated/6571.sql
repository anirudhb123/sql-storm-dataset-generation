WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        PostLinks pl ON pl.PostId = p.Id
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        AVG(rp.Score) AS AvgScore,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.AnswerCount) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON rp.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = u.Id)
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.AvgScore,
    ups.TotalViews,
    ups.TotalComments,
    ups.TotalAnswers,
    COUNT(DISTINCT b.Id) AS TotalBadges
FROM 
    UserPostStats ups
LEFT JOIN 
    Badges b ON b.UserId = ups.UserId
WHERE 
    ups.TotalAnswers > 0
GROUP BY 
    ups.UserId, ups.DisplayName, ups.AvgScore, ups.TotalViews, ups.TotalComments, ups.TotalAnswers
ORDER BY 
    ups.AvgScore DESC, ups.TotalViews DESC
LIMIT 10;
