WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.RankPerUser
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankPerUser <= 3 -- Top 3 per user
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount, -- Upvotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount -- Downvotes
    FROM 
        TopRankedPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.Score, tp.ViewCount
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    u.DisplayName AS AuthorName,
    u.Reputation AS AuthorReputation
FROM 
    PostDetails pd
JOIN 
    Users u ON pd.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
