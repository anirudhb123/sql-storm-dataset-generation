
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @prev_owner_user_id := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN 
        (SELECT @row_number := 0, @prev_owner_user_id := NULL) r
    WHERE 
        p.PostTypeId IN (1, 2)
        AND p.CreationDate >= CURRENT_DATE - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, OwnerDisplayName, CommentCount, UpVotes, DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    p.Title,
    CONCAT(ut.DisplayName, ' (Score: ', p.Score, ', Views: ', p.ViewCount, ')') AS PostSummary,
    p.CommentCount,
    (p.UpVotes - p.DownVotes) AS NetVotes
FROM 
    TopPosts p
JOIN 
    Users ut ON p.OwnerDisplayName = ut.DisplayName
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
