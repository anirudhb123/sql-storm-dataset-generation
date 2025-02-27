WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        (SELECT 
            COUNT(DISTINCT v.UserId) 
         FROM Votes v 
         WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT 
            COUNT(DISTINCT v.UserId) 
         FROM Votes v 
         WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore = 1
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        pht.Name AS HistoryTypeName
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    AND 
        ph.PostHistoryTypeId IN (10, 12, 13)  -- Focus on posts that were closed, deleted, or undeleted
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate AS PostCreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    ph.UserId AS HistorianUserId,
    ph.HistoryTypeName,
    ph.CreationDate AS HistoryDate
FROM 
    TopRankedPosts tp
LEFT JOIN 
    PostHistories ph ON tp.PostId = ph.PostId
WHERE 
    tp.UpVoteCount > tp.DownVoteCount
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC, ph.CreationDate DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;

-- This query evaluates performant aspects of posts while associating history, including:
-- 1. Rank-based filtering on posts by score within unique tags.
-- 2. Aggregation of comment and vote tallies through correlated subqueries.
-- 3. Analysis over a time frame combining CTEs for robust data management.
-- 4. Only selecting posts with more upvotes than downvotes and ordered effectively.
