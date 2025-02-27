WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY Score DESC) AS ScoreRank
    FROM 
        RankedPosts
)
SELECT 
    tp.*,
    ph.Name AS PostHistoryTypeName,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
LEFT JOIN 
    Users u ON tp.OwnerDisplayName = u.DisplayName
WHERE 
    tp.Rank <= 5 AND 
    tp.ScoreRank = 1
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
