WITH RecursiveCTE AS (
    -- Start with the first level of posts (Questions)
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions
    UNION ALL
    -- Recursive part to get answers to the questions
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        rc.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE rc ON rc.PostId = p.ParentId
    WHERE 
        p.PostTypeId = 2  -- Answers
),
AggregatedData AS (
    -- Calculate aggregates for users
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostTags AS (
    -- Tagging posts with hyperlink extraction
    SELECT
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM
        Posts p
    LEFT JOIN 
        LATERAL string_to_array(p.Tags, ',') AS tag ON true
    LEFT JOIN 
        Tags t ON t.Id::text = trim(both ' ' from tag)
    GROUP BY 
        p.Id
),
FinalOutput AS (
    SELECT
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        ud.DisplayName AS Creator,
        ud.TotalPosts,
        ud.TotalQuestions,
        ud.TotalAnswers,
        ud.PositivePosts,
        pt.Tags
    FROM 
        RecursiveCTE r
    JOIN 
        AggregatedData ud ON r.OwnerUserId = ud.UserId
    LEFT JOIN 
        PostTags pt ON r.PostId = pt.PostId
)
SELECT 
    fo.PostId,
    fo.Title,
    fo.CreationDate,
    fo.Score,
    fo.Creator,
    fo.TotalPosts,
    fo.TotalQuestions,
    fo.TotalAnswers,
    fo.PositivePosts,
    COALESCE(fo.Tags, 'No Tags') AS Tags
FROM 
    FinalOutput fo
WHERE 
    fo.Score > 5  -- Focus on high-scoring posts
ORDER BY 
    fo.Score DESC, 
    fo.CreationDate ASC
LIMIT 10;  -- Limit to 10 results for benchmarking
