WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ntile(5) OVER (ORDER BY COUNT(c.Id) DESC) AS CommentRank,
        ntile(5) OVER (ORDER BY COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) DESC) AS UpVoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        CommentRank,
        UpVoteRank
    FROM 
        RankedPosts
    WHERE 
        CommentRank = 1 OR UpVoteRank = 1
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    u.DisplayName AS OwnerName,
    CASE 
        WHEN tp.CommentCount > 50 THEN 'Highly Discussed'
        WHEN tp.UpVoteCount > 100 THEN 'Popular'
        ELSE 'Normal'
    END AS PostCategory,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
JOIN 
    Posts p ON tp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, '>') AS tagArray ON TRUE
LEFT JOIN 
    Tags t ON tagArray = t.TagName
GROUP BY 
    tp.PostId, u.DisplayName, tp.CommentCount, tp.UpVoteCount, tp.DownVoteCount
ORDER BY 
    tp.CommentCount DESC, tp.UpVoteCount DESC;
