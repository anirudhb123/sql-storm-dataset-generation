WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    COALESCE(b.Count, 0) AS TagCount,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    TopPosts p
LEFT JOIN 
    Badges b ON b.UserId = p.OwnerUserId
GROUP BY 
    p.PostId, p.Title, p.CreationDate, p.ViewCount, p.CommentCount, p.UpVotes, p.DownVotes, b.Count, b.Name
ORDER BY 
    p.ViewCount DESC, p.CreationDate DESC;
