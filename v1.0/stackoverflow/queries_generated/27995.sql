WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByTag
    FROM 
        Posts p
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate > NOW() - INTERVAL '1 year' -- Posts from the last year
),

TagAnalysis AS (
    SELECT 
        tags.TagName,
        COUNT(DISTINCT rp.PostId) AS QuestionCount,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViewCount
    FROM 
        RankedPosts rp
    JOIN 
        LATERAL (
            SELECT unnest(string_to_array(rp.Tags, '>')) AS TagName
        ) tags ON TRUE
    WHERE
        rp.RankByTag <= 5 -- Top 5 questions per tag
    GROUP BY
        tags.TagName
),

ClosingReasons AS (
    SELECT 
        p.Id AS PostId,
        MIN(ph.CreationDate) AS FirstCloseDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS int)
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        p.Id
)

SELECT 
    ta.TagName,
    ta.QuestionCount,
    ta.TotalScore,
    ta.AvgViewCount,
    COALESCE(cr.FirstCloseDate, 'N/A') AS FirstCloseDate,
    COALESCE(cr.CloseReasons, 'No Close Reasons') AS CloseReasons
FROM 
    TagAnalysis ta
LEFT JOIN 
    ClosingReasons cr ON ta.TagName = ANY (string_to_array(cr.PostId::text, ',')) -- Joining based on some correlation between Tags and Closing Reasons
ORDER BY 
    ta.QuestionCount DESC, 
    ta.TotalScore DESC;

