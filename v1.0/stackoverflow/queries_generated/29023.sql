WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        ARRAY_AGG(DISTINCT u.DisplayName) AS Contributors,
        AVG(UPPER(LEFT(p.Title, 20))) AS TitleLength,
        COUNT(DISTINCT v.UserId) AS VoteCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.TagName
),

CommonCloseReasons AS (
    SELECT 
        ph.Comment AS CloseReason,
        COUNT(*) AS ReasonCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10) -- Post Closed
    GROUP BY 
        ph.Comment
    ORDER BY 
        ReasonCount DESC
    LIMIT 5
)

SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ARRAY_TO_STRING(ts.Contributors, ', ') AS ContributorNames,
    ROUND(AVG(ts.TitleLength), 2) AS AvgTitleLength,
    COALESCE((SELECT STRING_AGG(CloseReason, ', ') FROM CommonCloseReasons), 'No close reasons') AS FrequentCloseReasons
FROM 
    TagStatistics ts
GROUP BY 
    ts.TagName
ORDER BY 
    ts.PostCount DESC
LIMIT 10;

-- The above query generates a list of the top 10 tags by post count, includes total questions and answers associated with each tag,
-- lists contributors for those posts, computes the average title length of posts associated with those tags,
-- and fetches the most common close reasons for the posts associated with those tags.
