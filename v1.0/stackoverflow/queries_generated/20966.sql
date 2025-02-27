WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2) -- Only questions and answers
),
PostScores AS (
    SELECT 
        PostId,
        SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1
            WHEN v.VoteTypeId = 3 THEN -1
            ELSE 0 
        END) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        PostId
),
PostTraits AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Author,
        ps.TotalVotes,
        (CASE 
            WHEN rp.Score >= 100 THEN 'Hot'
            WHEN rp.Score BETWEEN 50 AND 99 THEN 'Warm'
            WHEN rp.Score BETWEEN 1 AND 49 THEN 'Cool'
            ELSE 'Ice Cold' 
        END) AS Temperature
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostScores ps ON rp.PostId = ps.PostId
)
SELECT 
    pt.Title,
    pt.Author,
    pt.CreationDate,
    pt.Score,
    pt.ViewCount,
    pt.TotalVotes,
    pt.Temperature,
    COALESCE(ph.CloseReasonId, 'Not Closed') AS CloseReason,
    (
        SELECT STRING_AGG(TagName, ', ') 
        FROM Tags t 
        WHERE t.Id IN (
            SELECT DISTINCT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]))
            FROM Posts p 
            WHERE p.Id = pt.PostId
        )
    ) AS Tags,
    (
        SELECT COUNT(*) 
        FROM Comments c 
        WHERE c.PostId = pt.PostId
    ) AS CommentCount
FROM 
    PostTraits pt
LEFT JOIN 
    PostHistory ph ON pt.PostId = ph.PostId AND ph.PostHistoryTypeId = 10 -- Include only close records
WHERE 
    pt.Rank <= 5 -- Select top 5 per post type
ORDER BY 
    pt.Temperature DESC, pt.ViewCount DESC;

This SQL query showcases various advanced SQL features, including:

- Common Table Expressions (CTEs) for logical separation of the logic and readability.
- Window functions to rank posts within their type.
- A correlated subquery to aggregate tag names linked with posts.
- Use of `COALESCE` to handle possible `NULL` values.
- CASE statements for categorizing posts based on scores, creating semantical interpretations.
- LEFT joins to ensure the inclusion of all ranked posts even if they haven't been closed.
- Dealing with string manipulation and array functions to handle tag links. 

This intricate setup could serve to benchmark performance across multiple facets of SQL query abilities.
