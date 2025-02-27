WITH ProcessedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        ViewCount,
        CommentCount,
        UpVotes,
        DownVotes,
        (UpVotes - DownVotes) AS Score,
        RANK() OVER (ORDER BY (UpVotes - DownVotes) DESC, ViewCount DESC) AS Rank
    FROM 
        ProcessedPosts
)
SELECT 
    tp.Rank,
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.Score,
    pp.Tags
FROM 
    TopPosts tp
JOIN 
    ProcessedPosts pp ON tp.PostId = pp.PostId
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Rank;
