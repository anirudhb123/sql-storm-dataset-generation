WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '30 days' -- Last 30 days
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 -- Top 10 ranked questions
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(STRING_AGG(t.TagName, ', '), 'No Tags') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    LATERAL (SELECT STRING_AGG(t.TagName, ', ') AS TagName FROM Tags t WHERE t.Id IN (SELECT unnest(string_to_array(p.Tags, '>'))::int)) AS t
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.AnswerCount, tp.CommentCount, tp.UpVotes, tp.DownVotes
ORDER BY 
    tp.Score DESC;
