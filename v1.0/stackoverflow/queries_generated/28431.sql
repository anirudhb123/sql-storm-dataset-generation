WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        AVG(u.Reputation) AS AverageUserReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS ContributingUsers
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
TagWithTopPosts AS (
    SELECT 
        t.TagName,
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.ViewCount DESC) AS rn
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.TotalAnswers,
    ts.AverageUserReputation,
    ts.ContributingUsers,
    tp.Title AS TopPostTitle,
    tp.ViewCount AS TopPostViews,
    tp.CreationDate AS TopPostCreationDate
FROM 
    TagStatistics ts
LEFT JOIN 
    TagWithTopPosts tp ON ts.TagName = tp.TagName AND tp.rn = 1
ORDER BY 
    ts.PostCount DESC,
    ts.TotalViews DESC;
