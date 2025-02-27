WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '90 days'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.AnswerCount,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostsWithBadges AS (
    SELECT 
        tp.*,
        COUNT(b.Id) AS BadgeCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT u.Id FROM Users u WHERE u.DisplayName = tp.OwnerDisplayName)
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.OwnerDisplayName, tp.Score, tp.AnswerCount, tp.ViewCount, tp.CommentCount
)
SELECT 
    p.Title,
    p.OwnerDisplayName,
    p.Score,
    p.AnswerCount,
    p.ViewCount,
    p.CommentCount,
    p.BadgeCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM 
    PostsWithBadges p
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
