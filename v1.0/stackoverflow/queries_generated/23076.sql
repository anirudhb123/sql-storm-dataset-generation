WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR' 
        AND p.Score >= 0
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes,
        COALESCE(AVG(CASE WHEN v.VoteTypeId IN (2, 3) THEN CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE -1 END END), 0) AS AverageVoteValue
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostCommentCounts AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistoryComments AS (
    SELECT 
        ph.PostId,
        COUNT(ph.CommentId) AS HistoryCommentCount
    FROM 
        PostHistory ph
    WHERE 
        ph.Comment IS NOT NULL
    GROUP BY 
        ph.PostId
    HAVING 
        COUNT(ph.CommentId) > 0
)
SELECT 
    p.Title AS PostTitle,
    rp.Score,
    COALESCE(u.Upvotes, 0) AS UserUpvotes,
    COALESCE(u.Downvotes, 0) AS UserDownvotes,
    rp.PostCount,
    COALESCE(pcc.CommentCount, 0) AS PostCommentCount,
    COALESCE(phc.HistoryCommentCount, 0) AS HistoryCommentCount,
    CASE 
        WHEN rp.Score > 100 AND u.TotalVotes > 10 THEN 'Influential'
        WHEN rp.Score BETWEEN 50 AND 100 AND u.TotalVotes < 10 THEN 'Moderately Influential'
        ELSE 'Less Influential'
    END AS InfluenceLevel
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVoteStats u ON u.UserId = rp.PostId  -- Assuming PostId could potentially link back to UserId (for this example)
LEFT JOIN 
    PostCommentCounts pcc ON pcc.PostId = rp.PostId
LEFT JOIN 
    PostHistoryComments phc ON phc.PostId = rp.PostId
WHERE 
    rp.rn = 1 -- Selecting the most recent post of each type
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;

This SQL query combines several advanced SQL constructs including CTEs, window functions, outer joins, and aggregations. It ranks posts by creation date while also calculating various statistics regarding user votes and comments. It further categorizes posts into influence levels based on score and user engagement, making it quite comprehensive for performance benchmarking.
