
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
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    AND 
        p.PostTypeId = 1 
),
ScorePerTag AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) AS Tag,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
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
