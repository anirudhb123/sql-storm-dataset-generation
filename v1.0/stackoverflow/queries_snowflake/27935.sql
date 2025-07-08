
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        LISTAGG(b.Name, ',') AS BadgeNames,
        COUNT(c.Id) AS CommentCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TextAnalytics AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CommentCount,
        HasAcceptedAnswer,
        LENGTH(Body) - LENGTH(REPLACE(Body, ' ', '')) + 1 AS WordCount,
        COALESCE(NULLIF(COUNT(NULLIF(TRIM(value), '')) , 0), 1) AS TagCount
    FROM RankedPosts, LATERAL SPLIT_TO_TABLE(Tags, ' ') AS value
    GROUP BY PostId, Title, Body, Tags, CommentCount, HasAcceptedAnswer
),
Benchmark AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(WordCount) AS AvgWordsPerPost,
        SUM(CASE WHEN HasAcceptedAnswer = 1 THEN 1 ELSE 0 END) AS PostsWithAcceptedAnswers,
        AVG(CommentCount) AS AvgComments,
        SUM(TagCount) AS TotalTags
    FROM TextAnalytics
)
SELECT 
    bp.TotalPosts,
    bp.AvgWordsPerPost,
    bp.PostsWithAcceptedAnswers,
    bp.AvgComments,
    bp.TotalTags,
    CASE 
        WHEN bp.PostsWithAcceptedAnswers * 100.0 / bp.TotalPosts >= 50 THEN 'High Acceptance Rate'
        ELSE 'Low Acceptance Rate'
    END AS AcceptanceRateCategory
FROM Benchmark bp;
