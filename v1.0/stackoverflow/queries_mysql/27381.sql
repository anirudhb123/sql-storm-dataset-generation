
WITH TagAnalytics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(u.Reputation) AS AverageReputation,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS TotalQuestions,
        GROUP_CONCAT(DISTINCT u.DisplayName ORDER BY u.DisplayName ASC SEPARATOR ', ') AS UserNames
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        t.TagName
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pr.Name ORDER BY pr.Name ASC SEPARATOR ', ') AS CloseReasons,
        COUNT(DISTINCT ph.Id) AS ClosureCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes pr ON ph.Comment = pr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)

SELECT 
    ta.TagName,
    ta.PostCount,
    ta.AverageReputation,
    ta.TotalAnswers,
    ta.TotalQuestions,
    cp.CloseReasons,
    cp.ClosureCount,
    ta.UserNames
FROM 
    TagAnalytics ta
LEFT JOIN 
    ClosedPosts cp ON ta.PostCount = cp.PostId
ORDER BY 
    ta.PostCount DESC,
    ta.AverageReputation DESC;
