WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS Downvotes,
        (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t WHERE t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]))) AS AssociatedTags
    FROM
        Posts p
    WHERE
        p.Score > 0 AND
        p.CreationDate > NOW() - INTERVAL '1 month'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.Rank,
        rp.Upvotes,
        rp.Downvotes,
        rp.AssociatedTags,
        COALESCE(ph.votes, 0) AS TotalVoteCount,
        COALESCE(b.Class, 0) AS BadgeClass,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS votes FROM Votes GROUP BY PostId) ph ON rp.PostId = ph.PostId
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    WHERE
        b.Class IS NULL OR b.Class < 3  -- Exclude Gold badges for visibility
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.CreationDate, rp.Rank, rp.Upvotes, rp.Downvotes, b.Class
),
PostAnalytics AS (
    SELECT
        pd.*,
        CASE
            WHEN pd.Upvotes > pd.Downvotes THEN 'Positive'
            WHEN pd.Upvotes < pd.Downvotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment,
        DENSE_RANK() OVER (ORDER BY pd.Rank) AS OverallRank
    FROM 
        PostDetails pd
    WHERE 
        pd.Rank <= 10
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.Score,
    pa.ViewCount,
    pa.CreationDate,
    pa.VoteSentiment,
    pa.CommentCount,
    pa.AssociatedTags
FROM 
    PostAnalytics pa
WHERE 
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pa.PostId) < 5
ORDER BY 
    pa.OverallRank
LIMIT 20;

-- This query does the following:
-- 1. It ranks posts based on scores and view counts.
-- 2. It fetches upvote and downvote counts for each post using correlated subqueries.
-- 3. It retrieves associated tags using string aggregation and parsing.
-- 4. It uses common table expressions to organize the data, allowing for clearer logic and structure.
-- 5. It incorporates various joins, window functions, and predicates including conditional logic based on vote sentiment.
-- 6. It limits results to the top posts while filtering out posts with a significant number of comments.
