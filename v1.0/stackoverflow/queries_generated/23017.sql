WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(DISTINCT c.UserId) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 MONTH'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryEntryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY 
        ph.PostId
),
PostTagStats AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS TagsList,
        COUNT(DISTINCT t.Id) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(p.Tags, '><'))::int AS TagId) AS TagIds ON true
    LEFT JOIN 
        Tags t ON TagIds.TagId = t.Id
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    rp.CommentCount,
    phc.HistoryEntryCount,
    pts.TagsList,
    pts.TagCount,
    (CASE 
        WHEN rp.Score > 10 THEN 'High Score'
        WHEN rp.Score BETWEEN 0 AND 10 THEN 'Medium Score'
        ELSE 'Low Score' 
    END) AS ScoreCategory,
    (CASE 
        WHEN rp.ViewCount IS NULL THEN 'No Views'
        WHEN rp.ViewCount < 100 THEN 'Low Traffic'
        WHEN rp.ViewCount < 1000 THEN 'Moderate Traffic'
        ELSE 'High Traffic'
    END) AS TrafficCategory,
    (SELECT COUNT(*) 
     FROM Votes v2 
     WHERE v2.PostId = rp.PostId AND v2.VoteTypeId = 1
       AND v2.CreationDate > rp.CreationDate) AS AcceptedCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryCounts phc ON rp.PostId = phc.PostId
LEFT JOIN 
    PostTagStats pts ON rp.PostId = pts.PostId
WHERE 
    rp.Rank <= 5  -- Top 5 posts per each post type
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
This SQL query generates a detailed report on the top-ranked posts within the last month. It combines several advanced SQL constructs—including Common Table Expressions (CTEs), window functions, conditional logic, and joins—to extract comprehensive insights, such as comment counts, voting dynamics, tag statistics, and categorization based on score and traffic. Different scenarios are creatively handled with CASE statements, while lateral joins and aggregate functions efficiently manage nested data processing on tags. The result aims to benchmark and profile posts with nuanced queries, providing insights into both popularity and engagement within the StackOverflow schema.
