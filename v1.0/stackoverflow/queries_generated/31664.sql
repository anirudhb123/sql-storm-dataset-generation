WITH RecursivePostCTE AS (
    -- First, get all posts and their immediate child answers.
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only

    UNION ALL
    
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        a.CreationDate,
        a.Score,
        a.ViewCount,
        rp.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE rp ON a.ParentId = rp.PostId
    WHERE 
        a.PostTypeId = 2 -- Answers only
),

TagUsage AS (
    -- Aggregate tag usage statistics.
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%' -- Using pattern matching for tags
    GROUP BY 
        t.TagName
),

PostHistoryStatistics AS (
    -- Get statistics about post history.
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24) -- Title, Body edits and Suggested Edits
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    u.DisplayName AS OwnerDisplayName,
    rp.CreationDate AS QuestionCreationDate,
    rp.Score AS QuestionScore,
    rp.ViewCount AS QuestionViewCount,
    COALESCE(ph.EditCount, 0) AS EditCount,
    ph.LastEditDate,
    tu.TagName,
    tu.PostCount AS TagPostCount,
    tu.TotalViews AS TagTotalViews,
    tu.TotalScore AS TagTotalScore,
    RANK() OVER (PARTITION BY rp.PostId ORDER BY rp.Score DESC) AS ScoreRank -- Window function for ranking
FROM 
    RecursivePostCTE rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    PostHistoryStatistics ph ON rp.PostId = ph.PostId
LEFT JOIN 
    TagUsage tu ON tu.PostCount > 0  -- Get tags with at least one associated post
WHERE 
    rp.Level = 1  -- Only select top-level questions
ORDER BY 
    rp.CreationDate DESC
LIMIT 100; -- Optional limit for performance
