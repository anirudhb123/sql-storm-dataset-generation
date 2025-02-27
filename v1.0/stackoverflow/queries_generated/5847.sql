WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        OwnerDisplayName, 
        ViewCount, 
        AnswerCount, 
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostStatistics AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        TopPosts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.PostId = c.PostId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(DISTINCT Id) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = p.PostId)
)
SELECT 
    ps.*, 
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 2) AS Upvotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 3) AS Downvotes
FROM 
    PostStatistics ps
ORDER BY 
    ps.Score DESC
LIMIT 50;
