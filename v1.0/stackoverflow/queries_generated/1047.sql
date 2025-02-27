WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS comment_count,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS upvote_count,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS downvote_count
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS user_rank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostSummary AS (
    SELECT 
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        tu.DisplayName AS TopUser,
        rp.comment_count,
        (rp.upvote_count - rp.downvote_count) AS net_votes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopUsers tu ON rp.OwnerUserId = tu.UserId
    WHERE 
        rp.rn = 1
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.TopUser,
    ps.comment_count,
    ps.net_votes,
    CASE 
        WHEN ps.net_votes IS NULL THEN 'No votes'
        WHEN ps.net_votes > 0 THEN 'Positive'
        WHEN ps.net_votes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS vote_status
FROM 
    PostSummary ps
ORDER BY 
    ps.Score DESC
LIMIT 10;
