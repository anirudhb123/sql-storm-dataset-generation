WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.Score IS NOT NULL
),

TopRankedPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Score IS NULL THEN 'No score available'
            ELSE CONCAT('Score: ', rp.Score)
        END AS ScoreDescription,
        CASE 
            WHEN rp.CommentCount = 0 THEN 'No comments'
            ELSE CONCAT(rp.CommentCount, ' comments')
        END AS CommentDescription
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),

PostDetails AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.ViewCount,
        trp.Score,
        trp.CreationDate,
        trp.ScoreDescription,
        trp.CommentDescription,
        COALESCE((
            SELECT STRING_AGG(CONCAT(u.DisplayName, ' (', u.Reputation, ' points)'), ', ')
            FROM Users u
            JOIN Comments c ON c.UserId = u.Id
            WHERE c.PostId = trp.PostId
        ), 'No commenters') AS TopCommenters
    FROM 
        TopRankedPosts trp
)

SELECT 
    pd.PostId, 
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.CreationDate,
    pd.ScoreDescription,
    pd.CommentDescription,
    pd.TopCommenters,
    COALESCE((
        SELECT STRING_AGG(hl.Comment, '; ') 
        FROM PostHistory ph
        JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
        WHERE ph.PostId = pd.PostId AND (pht.Name ILIKE '%close%' OR pht.Name ILIKE '%delete%')
    ), 'No history events') AS HistoryEvents
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC NULLS LAST, pd.CreationDate DESC 
LIMIT 100;
