WITH RecursiveTags AS (
    SELECT 
        Id,
        TagName,
        Count,
        ExcerptPostId,
        WikiPostId,
        1 AS Level
    FROM Tags
    WHERE IsRequired = 1

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        t.ExcerptPostId,
        t.WikiPostId,
        rt.Level + 1
    FROM Tags t
    INNER JOIN RecursiveTags rt ON t.ExcerptPostId = rt.Id
),
PostInsights AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreatedDate DESC) AS OwnerPostRank,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY p.Id, p.Title, p.ViewCount, p.Score, p.OwnerUserId
),
RankedPostInsights AS (
    SELECT 
        pi.*,
        CASE 
            WHEN pi.OwnerPostRank = 1 THEN 'Latest'
            ELSE 'Previous'
        END AS PostStatus,
        (pi.UpvoteCount - pi.DownvoteCount) AS NetVotes
    FROM PostInsights pi
)
SELECT 
    r.Id AS TagId,
    r.TagName,
    COUNT(r.PostId) AS PostCount,
    AVG(pi.Score) AS AverageScore,
    SUM(pi.ViewCount) AS TotalViews,
    SUM(CASE WHEN pi.NetVotes > 0 THEN 1 ELSE 0 END) AS PositiveEngagements
FROM RecursiveTags r
LEFT JOIN Posts p ON p.Tags LIKE '%' || r.TagName || '%'
LEFT JOIN RankedPostInsights pi ON pi.PostId = p.Id
GROUP BY r.Id, r.TagName
HAVING COUNT(r.PostId) > 0
ORDER BY TotalViews DESC, AverageScore DESC;

-- Include additional information on posts with accepted answers
WITH AcceptedAnswers AS (
    SELECT 
        p.Id AS QuestionId,
        p.AcceptedAnswerId,
        a.Score AS AcceptedAnswerScore
    FROM Posts p
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id
    WHERE p.PostTypeId = 1
)
SELECT 
    pa.TagId,
    ta.TagName,
    COUNT(pa.QuestionId) AS QuestionsWithAcceptedAnswers,
    AVG(aa.AcceptedAnswerScore) AS AvgAcceptedScore
FROM AcceptedAnswers aa
JOIN Posts p ON p.Id = aa.QuestionId
JOIN RecursiveTags ta ON p.Tags LIKE '%' || ta.TagName || '%'
GROUP BY ta.TagId, ta.TagName
HAVING COUNT(pa.QuestionId) > 0;

