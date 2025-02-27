WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(p.CommentCount, 0)) AS TotalComments,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClasses,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
CombinedStats AS (
    SELECT 
        ts.TagName,
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        ts.PostCount,
        ts.TotalViews,
        ts.TotalAnswers,
        ts.TotalComments,
        ts.AverageScore,
        phs.EditCount,
        phs.ClosedDate
    FROM 
        TagStats ts
    JOIN 
        UserStats us ON ts.PostCount > 0
    LEFT JOIN 
        PostHistoryStats phs ON ts.PostCount = phs.PostId
)
SELECT 
    TagName,
    DisplayName,
    TotalPosts,
    PostCount,
    TotalViews,
    TotalAnswers,
    TotalComments,
    AverageScore,
    EditCount,
    ClosedDate
FROM 
    CombinedStats
WHERE 
    TotalPosts > 5
ORDER BY 
    TotalViews DESC, AverageScore DESC;
