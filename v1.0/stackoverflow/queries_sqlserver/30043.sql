
WITH TrendingPosts AS (
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
        p.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
    AND 
        p.PostTypeId = 1 
),
ScorePerTag AS (
    SELECT 
        value AS Tag,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '>') AS TagSplit
    WHERE 
        p.Score IS NOT NULL
    GROUP BY 
        value
),
PopularTags AS (
    SELECT 
        Tag,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS TagRank
    FROM 
        ScorePerTag
    WHERE 
        TotalScore > 100 
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
        ph.PostHistoryTypeId = 10 
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
    PopularTags pt ON tp.Rank <= 10 AND EXISTS (SELECT 1 FROM ScorePerTag WHERE Tag = pt.Tag)
LEFT JOIN 
    ScorePerTag t ON pt.Tag = t.Tag
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = tp.Id
WHERE 
    tp.Score > (SELECT AVG(Score) FROM Posts) AND tp.Rank <= 15
ORDER BY 
    tp.CreationDate DESC, 
    t.TotalScore DESC;
