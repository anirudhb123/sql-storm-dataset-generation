WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS ClosedCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body, 
        rp.Tags, 
        rp.OwnerDisplayName, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.CommentCount, 
        rp.VoteCount, 
        rp.ClosedCount,
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC, rp.CreationDate ASC) AS RowNum
    FROM 
        RankedPosts rp
    WHERE 
        rp.ClosedCount > 0 -- Only include posts that have been closed
)
SELECT 
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.ViewCount,
    fp.CommentCount,
    fp.VoteCount
FROM 
    FilteredPosts fp
WHERE 
    fp.RowNum <= 10 -- Limit output to top 10 closed questions
ORDER BY 
    fp.ViewCount DESC, fp.CreationDate ASC;

This SQL query benchmarks string processing by retrieving the top 10 closed questions based on view count while also including relevant metrics such as comment count, vote count, and owner details. It utilizes common table expressions (CTEs) to rank and filter the data efficiently, demonstrating advanced SQL techniques suitable for performance analysis in a scenario involving string data and user interactions.
