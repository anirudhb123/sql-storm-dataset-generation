
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.CreationDate,
        @row_number := IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId,
        COALESCE(u.Reputation, 0) AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id,
        (SELECT @row_number := 0, @prev_post_type := NULL) AS vars
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY
    ORDER BY 
        p.PostTypeId, p.Score DESC
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY
    GROUP BY 
        c.PostId
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.AnswerCount,
    rp.ViewCount,
    rp.CreationDate,
    rp.Rank,
    rc.CommentCount,
    rc.LastCommentDate,
    COALESCE(pv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pv.DownVotes, 0) AS TotalDownVotes,
    rp.OwnerReputation
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
