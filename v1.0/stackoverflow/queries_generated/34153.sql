WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE
        p.PostTypeId = 1 -- Only Questions
    GROUP BY
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.ViewCount IS NULL THEN 0 
            ELSE rp.ViewCount 
        END AS AdjustedViewCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        Rank <= 5 -- Get top 5 latest posts per user
),
PostHistories AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstChangeDate,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Close, Reopen, Delete
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
PostAggregates AS (
    SELECT
        fp.PostId,
        FIRST_VALUE(fp.Title) OVER (PARTITION BY fp.PostId ORDER BY fp.CreationDate) AS FirstTitle,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.ChangeCount END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.ChangeCount END) AS ReopenCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.ChangeCount END) AS DeleteCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostHistories ph ON fp.PostId = ph.PostId
    GROUP BY 
        fp.PostId
)
SELECT 
    pa.PostId,
    pa.FirstTitle,
    fp.Author,
    fp.AdjustedViewCount,
    fp.UpvoteCount,
    pa.CloseCount,
    pa.ReopenCount,
    pa.DeleteCount,
    DATEDIFF('second', fp.CreationDate, CURRENT_TIMESTAMP) AS AgeInSeconds
FROM 
    PostAggregates pa
JOIN 
    FilteredPosts fp ON pa.PostId = fp.PostId
WHERE 
    (pa.CloseCount > 0 OR pa.ReopenCount > 0 OR pa.DeleteCount > 0) -- Include only modified or deleted posts
ORDER BY 
    fp.Score DESC, 
    AgeInSeconds DESC -- Ordering by score and age for benchmark analysis
LIMIT 100;
