WITH TagAnalysis AS (
    SELECT 
        t.TagName,
        p.Title AS PostTitle,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        LENGTH(p.Body) AS BodyLength,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBounty,
        STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8  -- Only counting BountyStarts
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions
    GROUP BY 
        t.TagName, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount
),
RankedTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TotalQuestions,
        AVG(ViewCount) AS AvgViews,
        AVG(AnswerCount) AS AvgAnswers,
        AVG(CommentCount) AS AvgComments,
        SUM(BodyLength) AS TotalBodyLength,
        AVG(AvgBounty) AS AvgBounty,
        STRING_AGG(DISTINCT BadgeNames, '; ') AS CombinedBadges,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS Rank
    FROM 
        TagAnalysis
    GROUP BY 
        TagName
)

SELECT 
    TagName,
    TotalQuestions,
    AvgViews,
    AvgAnswers,
    AvgComments,
    TotalBodyLength,
    AvgBounty,
    CombinedBadges
FROM 
    RankedTags
WHERE 
    Rank <= 10  -- Top 10 tags with most questions
ORDER BY 
    TotalQuestions DESC;
