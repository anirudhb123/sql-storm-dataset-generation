
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS Author,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate > (NOW() - INTERVAL 1 YEAR)
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1) AS Tag,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
         UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) 
         -CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenVotes,
        MAX(ph.CreationDate) AS LastEdit
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Tags,
    rp.Author,
    rp.Score,
    ts.TotalPosts,
    ts.UpvotedPosts,
    ts.DownvotedPosts,
    phs.CloseVotes,
    phs.ReopenVotes,
    phs.LastEdit
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON ts.Tag = SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '>', numbers.n), '>', -1)
JOIN 
    PostHistoryStats phs ON phs.PostId = rp.PostId
JOIN 
    (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
     UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(rp.Tags) 
     -CHAR_LENGTH(REPLACE(rp.Tags, '>', '')) >= numbers.n - 1
WHERE 
    rp.TagRank <= 5  
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
