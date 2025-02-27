WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Owner,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5  -- Top 5 posts per post type
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Owner,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    pt.Name AS PostTypeName,
    ph.Comment AS EditComment
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostId = pt.Id
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId AND ph.PostHistoryTypeId = 24  -- Suggested Edit Applied
ORDER BY 
    tp.CreationDate DESC;
