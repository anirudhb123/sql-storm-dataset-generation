WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.ViewCount > (SELECT AVG(ViewCount) FROM Posts)  -- Posts with above average views
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        pht.Name AS HistoryType,
        ph.UserDisplayName,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 
                (SELECT Name FROM CloseReasonTypes WHERE Id = CAST(JSONB_EXTRACT_PATH_TEXT(ph.Comment, 'CloseReasonId') AS SMALLINT))
            ELSE NULL
        END AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 month' 
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    phd.HistoryType,
    phd.UserDisplayName,
    phd.HistoryDate,
    COALESCE(phd.CloseReason, 'N/A') AS CloseReason,
    ARRAY_AGG(CONCAT(u.DisplayName, ': ', v.VoteTypeId)) AS UserVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN 
    Votes v ON rp.PostId = v.PostId
LEFT JOIN 
    Users u ON v.UserId = u.Id
WHERE 
    rp.RankScore <= 5  -- Only top 5 posts per type
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.CommentCount, 
    phd.HistoryType, phd.UserDisplayName, phd.HistoryDate
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100;  -- Limit results to 100 for performance

In this elaborate SQL query:

- **CTEs (Common Table Expressions)** are created to rank posts based on their score and to gather details of recent post history.
- **Window functions** are used to rank posts by their score within their post type.
- A **LEFT JOIN** is utilized between posts and comments to count comments related to each post.
- Another **LEFT JOIN** connects post history to extract the user's display name and a derived column for close reasons, demonstrating conditional logic with **CASE** and JSONB manipulation.
- User votes are aggregated using `ARRAY_AGG` to collate all associated votes for each post.
- Finally, we apply various filtering conditions, including date constraints and limits on ranks, to ensure performance and relevance of the results.
- The overall structure reflects a complex nature with a mix of joins, window functions, and CTEs aimed at digging deeper into the StackOverflow schema.
