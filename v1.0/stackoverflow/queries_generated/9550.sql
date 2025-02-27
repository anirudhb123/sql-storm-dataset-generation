WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.*,
    pt.Name AS PostType,
    COUNT(b.Id) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostTypes pt ON tp.PostId = pt.Id
LEFT JOIN 
    Badges b ON b.UserId = tp.OwnerDisplayName
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.OwnerDisplayName, tp.CommentCount, tp.UpVotes, tp.DownVotes, pt.Name
ORDER BY 
    tp.UpVotes DESC, tp.CommentCount DESC;
