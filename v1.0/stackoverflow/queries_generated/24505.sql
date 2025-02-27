WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByDate,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '365 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        pt.Name AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON pt.Id = ph.PostHistoryTypeId
    WHERE 
        pt.Name = 'Post Closed'
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        cp.UserId AS ClosedBy,
        cp.CreationDate AS ClosedDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON cp.PostId = rp.PostId
    WHERE 
        rp.RankByDate <= 5 -- Only get top 5 posts by rank
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.ViewCount,
    fr.Score,
    fr.CommentCount,
    fr.UpVoteCount,
    fr.DownVoteCount,
    COALESCE(fr.ClosedBy, -1) AS ClosedByCitizenId,
    COALESCE(fr.ClosedDate, '1970-01-01') AS ClosedDate
FROM 
    FinalResults fr
WHERE 
    fr.ViewCount > 10
ORDER BY 
    fr.Score DESC, 
    fr.CreationDate ASC;

-- This query ranks posts from the last year by their creation date, counts comments and votes,
-- retrieves closing details if the post is closed, and shows the top 5 posts by rank with 
-- a specific filtering criterion on view counts. Cases where a post has not been closed are handled
-- using COALESCE to provide default values. 
