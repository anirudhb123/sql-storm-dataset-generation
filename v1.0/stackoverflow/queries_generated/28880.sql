WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        TopUsers,
        BadgeCount,
        CommentCount,
        RANK() OVER (ORDER BY AverageScore DESC, PostCount DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    TagName,
    PostCount,
    TotalViews,
    AverageScore,
    TopUsers,
    BadgeCount,
    CommentCount
FROM 
    TopTags
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
This SQL query benchmarks string processing by analyzing tag statistics across posts in the Stack Overflow schema. It identifies the top 10 tags based on average score and post count while aggregating user participation and comment counts.
