WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AcceptedAnswerId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        CASE 
            WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Has Accepted Answer'
            ELSE 'No Accepted Answer'
        END AS AnswerStatus,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByDate <= 5
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.AnswerStatus,
    pd.UpVotes,
    pd.DownVotes,
    pd.Score * 1.0 / NULLIF(pd.UpVotes + pd.DownVotes, 0) AS VoteEfficiency /* Handling division by zero using NULLIF */
FROM 
    PostDetails pd
WHERE 
    pd.ViewCount > (SELECT AVG(ViewCount) FROM Posts) /* Only posts with above average views */
ORDER BY 
    pd.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;

-- Unusual semantics: Query also checks NULL logic for VoteEfficiency.
-- It includes outer joins, correlated subqueries, filtering by calculated average, window functions, and complicated predicates.
