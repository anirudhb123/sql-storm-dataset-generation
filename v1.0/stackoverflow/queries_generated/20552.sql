WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(p.AcceptedAnswerId, -1) AS AnswerId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  -- Questions and Answers
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        LATERAL (SELECT DISTINCT UNNEST(string_to_array(rp.Tags, '><')) AS TagName) t ON TRUE
    WHERE 
        rp.rn <= 5  -- Top 5 by creation date per post type
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score
),
PostScoreSummary AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ViewCount,
        fp.Score,
        COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS NetVotes
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
            Votes 
         GROUP BY 
            PostId) v ON v.PostId = fp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.NetVotes,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ps.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = ps.PostId AND ph.PostHistoryTypeId IN (10, 11)) AS ClosureHistory,
    (SELECT MIN(CreationDate) 
     FROM PostHistory ph 
     WHERE ph.PostId = ps.PostId AND ph.PostHistoryTypeId = 1) AS FirstEditDate  -- Interested in first title history
FROM 
    PostScoreSummary ps
WHERE 
    ps.NetVotes IS NOT NULL
ORDER BY 
    ps.NetVotes DESC,
    ps.Score DESC
LIMIT 50 OFFSET 10;  -- Pagination

This SQL query leverages common table expressions (CTEs) and various SQL constructs such as window functions, string manipulation, and subqueries to create a detailed report. It summarizes posts for the past year by post type, incorporates comment counts, analyzes vote scores, and explores post history for specific closure events, showcasing intricate SQL logic and ensuring it remains efficient even in complex scenarios.
