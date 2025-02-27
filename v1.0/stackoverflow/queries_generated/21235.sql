WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) OVER (PARTITION BY p.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Rank,
        COALESCE(NULLIF(rp.CommentCount, 0), 1) AS EffectiveCommentCount,
        COALESCE(NULLIF(rp.VoteCount, 0), 1) AS EffectiveVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS RevisionCount,
        MAX(ph.CreationDate) AS LastRevisionDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.EffectiveCommentCount,
    fp.EffectiveVoteCount,
    pha.HistoryTypes,
    pha.RevisionCount,
    pha.LastRevisionDate,
    CASE 
        WHEN fp.Score IS NULL THEN 'No Score'
        WHEN fp.Score > 100 THEN 'Highly Rated'
        ELSE 'Average Rated'
    END AS RatingCategory,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId = 2) 
        THEN 'Has Upvotes'
        ELSE 'No Upvotes'
    END AS UpvoteStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryAggregated pha ON fp.PostId = pha.PostId
WHERE 
    fp.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;

-- Additional complexity: correlating with user reputation and badges
SELECT 
    post_stats.*,
    u.Reputation AS OwnerReputation,
    COUNT(b.Id) AS BadgeCount,
    STRING_AGG(b.Name, ', ') AS BadgeNames
FROM 
    (
        SELECT 
            fp.PostId,
            SUM(fp.Score) OVER (PARTITION BY u.Id) AS UserTotalScore,
            COUNT(DISTINCT c.Id) AS CommentsMade
        FROM 
            FilteredPosts fp
        JOIN 
            Users u ON fp.PostId = u.Id
        LEFT JOIN 
            Comments c ON fp.PostId = c.PostId
        GROUP BY 
            fp.PostId, u.Id
    ) post_stats
LEFT JOIN 
    Users u ON u.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = post_stats.PostId)
LEFT JOIN 
    Badges b ON b.UserId = u.Id
GROUP BY 
    post_stats.PostId, u.Reputation
ORDER BY 
    OwnerReputation DESC;
