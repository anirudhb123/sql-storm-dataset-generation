
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.AnswerCount,
    rp.UpvoteCount,
    rp.DownvoteCount
FROM 
    (SELECT 
        rp.*, 
        @row_number := IF(@prev_user = rp.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_user := rp.OwnerUserId
     FROM 
        RankedPosts rp, (SELECT @row_number := 0, @prev_user := NULL) AS vars
     ORDER BY 
        rp.OwnerUserId, rp.CreationDate DESC) AS ranked_rp
JOIN 
    UserReputation up ON ranked_rp.PostRank = 1 AND up.UserId = ranked_rp.OwnerUserId
ORDER BY 
    up.Reputation DESC, ranked_rp.Score DESC
LIMIT 10;
