WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (2, 3) -- Only include Upvotes and Downvotes
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>><<'))::varchar[]) AS t(TagName) ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        CASE 
            WHEN rp.RankByScore = 1 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory,
        rp.CommentCount,
        rp.VoteCount,
        COALESCE(NULLIF(rp.Tags, ''), 'No Tags') AS Tags
    FROM 
        RankedPosts rp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.PostCategory,
    ps.CommentCount,
    ps.VoteCount,
    CASE 
        WHEN ps.Score > 100 THEN 'Highly Rated'
        WHEN ps.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory,
    (SELECT COUNT(*) FROM Posts p WHERE p.AcceptedAnswerId = ps.PostId) AS AcceptedAnswers,
    (SELECT AVG(v.BountyAmount) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 8) AS AverageBounty,
    (SELECT STRING_AGG(DISTINCT ur.DisplayName, ', ') 
     FROM Users ur 
     INNER JOIN Badges b ON ur.Id = b.UserId 
     WHERE b.Class = 1 AND b.Date >= NOW() - INTERVAL '2 years') AS GoldBadgers
FROM 
    PostSummary ps
ORDER BY 
    ps.ViewCount DESC NULLS LAST, 
    ps.Score DESC;
