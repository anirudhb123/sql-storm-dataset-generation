WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        U.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpvoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownvoteCount,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '30 days'  -- Posts in the last 30 days
    GROUP BY 
        p.Id, U.DisplayName
), TopPosts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC) AS ViewRank
    FROM 
        RankedPosts rp
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.ViewCount,
    t.Score,
    t.Owner,
    t.CommentCount,
    t.UpvoteCount,
    t.DownvoteCount,
    t.ScoreRank,
    t.ViewRank
FROM 
    TopPosts t
WHERE 
    t.ScoreRank <= 10  -- Top 10 posts by score
    AND t.ViewRank <= 10  -- Top 10 posts by views
ORDER BY 
    t.ScoreRank, t.ViewRank;
