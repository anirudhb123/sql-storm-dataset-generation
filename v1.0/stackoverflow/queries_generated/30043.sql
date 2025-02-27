WITH RECURSIVE TrendingPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    AND 
        p.PostTypeId = 1 -- Only Questions
),
ScorePerTag AS (
    SELECT 
        unnest(string_to_array(p.Tags, '>')) AS Tag,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS TagRank
    FROM 
        ScorePerTag
    WHERE 
        TotalScore > 100 -- Only tags with a substantial score
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed posts
)

SELECT 
    tp.Id AS PostID,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    pt.Tag AS PopularTag,
    t.TotalScore AS TagTotalScore,
    cp.CreationDate AS ClosedDate,
    cp.UserDisplayName AS ClosedBy,
    cp.Comment AS CloseReason
FROM 
    TrendingPosts tp
LEFT JOIN 
    PopularTags pt ON tp.Rank <= 10 AND EXISTS (SELECT 1 FROM ScorePerTag where Tag = pt.Tag)
LEFT JOIN 
    ScorePerTag t ON pt.Tag = t.Tag
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = tp.Id
WHERE 
    tp.Score > (SELECT AVG(Score) FROM Posts) AND tp.Rank <= 15
ORDER BY 
    tp.CreationDate DESC, 
    t.TotalScore DESC;

This SQL query is designed to benchmark performance by retrieving trending questions from StackOverflow over the last 30 days, their correlated scores per popular tag, and a list of any related closed posts. The inclusion of multiple CTEs with analytical functions and various joins simulates complex data retrieval scenarios while using performance techniques like `EXISTS` for optimization.
