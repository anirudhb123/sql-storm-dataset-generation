
WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        (SELECT COUNT(*) FROM (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', numbers.n), '<>', -1)) AS Tag FROM 
            (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
            WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '<>', '')) >= numbers.n - 1) AS TagCount) AS TagCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COALESCE(b.Name, 'No Badge') AS OwnerBadge,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS RecentPostRank,
        @current_user := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 
    CROSS JOIN (SELECT @row_number := 0, @current_user := NULL) AS r
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),

TagPerformance AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(pa.Tags, '<>', numbers.n), '<>', -1)) AS TagName,
        COUNT(*) AS QuestionCount,
        SUM(pa.ViewCount) AS TotalViews,
        SUM(pa.Score) AS TotalScore,
        AVG(pa.AnswerCount) AS AvgAnswerCount
    FROM 
        PostAnalytics pa
    JOIN 
        Posts p ON pa.PostId = p.Id
    CROSS JOIN (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
    GROUP BY 
        TagName
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
LIMIT 10;
