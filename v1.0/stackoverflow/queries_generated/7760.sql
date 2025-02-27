WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' 
        AND p.PostTypeId IN (1, 2) -- Questions and Answers only
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        OwnerName,
        Score,
        CommentCount,
        NetVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.*, 
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     JOIN Posts pt ON t.Id = ANY(string_to_array(pt.Tags, ', ')::int[])
     WHERE pt.Id = tp.PostId) AS Tags
FROM 
    TopPosts tp
ORDER BY 
    NetVotes DESC, 
    Score DESC;
