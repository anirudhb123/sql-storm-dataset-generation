
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        @row_number := IF(@current_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @current_owner_user_id := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COALESCE(NULLIF(u.Reputation, 0), 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_number := 0, @current_owner_user_id := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
        AND (p.ViewCount > 100 OR u.Reputation > 50)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId, p.Score, u.Reputation
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        PostRank,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        UserReputation
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
),
FinalPosts AS (
    SELECT 
        tp.*,
        pt.Name AS PostTypeName
    FROM 
        TopPosts tp
    INNER JOIN 
        PostTypes pt ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.PostTypeId = pt.Id)
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.UserReputation,
    fp.PostTypeName
FROM 
    FinalPosts fp
ORDER BY 
    fp.ViewCount DESC, 
    fp.UpVoteCount DESC
LIMIT 10;
