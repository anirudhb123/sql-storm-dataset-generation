WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.AnswerCount) AS AvgAnswers,
        AVG(rp.CommentCount) AS AvgComments,
        MAX(rp.ViewCount) AS MaxViews,
        MAX(rp.Score) AS MaxScore
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    GROUP BY 
        u.DisplayName
),
TopContributors AS (
    SELECT 
        DisplayName,
        TotalPosts,
        TotalViews,
        TotalScore,
        AvgAnswers,
        AvgComments,
        MaxViews,
        MaxScore,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        PostStats
)

SELECT 
    tc.DisplayName,
    tc.TotalPosts,
    tc.TotalViews,
    tc.TotalScore,
    tc.AvgAnswers,
    tc.AvgComments,
    tc.MaxViews,
    tc.MaxScore
FROM 
    TopContributors tc
WHERE 
    Rank <= 10
ORDER BY 
    TotalScore DESC, TotalViews DESC;
