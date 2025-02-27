WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(
            (SELECT COUNT(*) 
             FROM Comments c 
             WHERE c.PostId = p.Id), 
            0) AS CommentCount,
        COALESCE(
            (SELECT COUNT(*) 
             FROM Votes v 
             WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 
            0) AS UpVoteCount,
        COALESCE(
            (SELECT COUNT(*) 
             FROM Votes v 
             WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 
            0) AS DownVoteCount,
        (
            SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
            FROM Tags t 
            WHERE t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int) )
        ) AS TagsList
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
EnhancedRank AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.CommentCount = 0 THEN 'No Comments'
            WHEN rp.CommentCount <= 2 THEN 'Few Comments'
            ELSE 'Many Comments' 
        END AS CommentCategory,
        CASE 
            WHEN rp.UpVoteCount - rp.DownVoteCount < 0 THEN 'Negative Feedback' 
            WHEN rp.UpVoteCount - rp.DownVoteCount > 0 THEN 'Positive Feedback' 
            ELSE 'Neutral' 
        END AS FeedbackCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    e.PostId, 
    e.Title, 
    e.CreationDate, 
    e.CommentCount, 
    e.UpVoteCount, 
    e.DownVoteCount, 
    e.TagsList, 
    e.CommentCategory, 
    e.FeedbackCategory
FROM 
    EnhancedRank e
LEFT JOIN 
    Badges b ON e.PostId = b.UserId
GROUP BY 
    e.PostId, e.Title, e.CreationDate, e.CommentCount, e.UpVoteCount, e.DownVoteCount, e.TagsList, e.CommentCategory, e.FeedbackCategory
HAVING 
    COUNT(b.Id) >= 2 -- At least 2 badges
ORDER BY 
    e.Score DESC, 
    e.CreationDate DESC
LIMIT 10;

-- Additional consideration for testing NULL and bizarre case handling
SELECT 
    p.Id AS PostId,
    p.Title,
    (SELECT COALESCE(MIN(c.CreationDate), 'No comments') 
     FROM Comments c 
     WHERE c.PostId = p.Id) AS EarliestComment,
    CASE 
        WHEN p.ViewCount IS NULL THEN 'View count unknown' 
        ELSE p.ViewCount::TEXT 
    END AS ViewCountStatus
FROM 
    Posts p
WHERE 
    p.AcceptedAnswerId IS NULL
ORDER BY 
    p.Title ASC NULLS LAST;
