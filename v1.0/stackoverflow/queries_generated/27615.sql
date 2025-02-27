WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Filter for Questions only
),
QuestionTagStats AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) as QuestionCount,
        SUM(ViewCount) as TotalViews,
        SUM(Score) as TotalScore
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Questions Only
    GROUP BY 
        Tag
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(ct.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON ph.Comment::int = ct.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    qt.QuestionCount,
    qt.TotalViews,
    qt.TotalScore,
    cp.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    QuestionTagStats qt ON rp.Tags LIKE '%' || qt.Tag || '%'
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 5 -- Selecting top 5 posts per user based on score
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC;
