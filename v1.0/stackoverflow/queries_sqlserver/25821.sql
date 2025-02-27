
WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        (SELECT COUNT(*) FROM STRING_SPLIT(p.Tags, '<>')) AS TagCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COALESCE(b.Name, 'No Badge') AS OwnerBadge,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),

TagPerformance AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS QuestionCount,
        SUM(pa.ViewCount) AS TotalViews,
        SUM(pa.Score) AS TotalScore,
        AVG(pa.AnswerCount) AS AvgAnswerCount
    FROM 
        PostAnalytics pa
    CROSS APPLY 
        STRING_SPLIT(pa.Tags, '<>') 
    GROUP BY 
        value
)

SELECT 
    tp.TagName,
    tp.QuestionCount,
    tp.TotalViews,
    tp.TotalScore,
    tp.AvgAnswerCount,
    CASE 
        WHEN tp.QuestionCount > 100 THEN 'High Engagement'
        WHEN tp.QuestionCount BETWEEN 50 AND 100 THEN 'Moderate Engagement'
        ELSE 'Low Engagement' 
    END AS EngagementLevel
FROM 
    TagPerformance tp
ORDER BY 
    tp.TotalScore DESC, 
    tp.QuestionCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
