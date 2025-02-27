
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, Score, ViewCount, CreationDate, OwnerDisplayName, 
        CommentCount, UpVoteCount, DownVoteCount,
        @row_number := @row_number + 1 AS Rank
    FROM 
        RankedPosts, (SELECT @row_number := 0) AS rn
    ORDER BY 
        Score DESC, ViewCount DESC
)
SELECT 
    PostId, Title, Score, ViewCount, CreationDate, OwnerDisplayName, 
    CommentCount, UpVoteCount, DownVoteCount
FROM 
    TopPosts
WHERE 
    Rank <= 10;
