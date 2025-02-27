WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(u.DisplayName, 'Community User') AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, AnswerCount, CommentCount, Owner 
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
),
PostMetrics AS (
    SELECT 
        t.PostId,
        t.Title,
        t.CreationDate,
        t.Score,
        t.ViewCount,
        t.AnswerCount,
        t.CommentCount,
        ROUND(AVG(coalesce(voteCount, 0)), 2) AS AvgVotes,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT tag.TagName, ', ') AS Tags
    FROM 
        TopPosts t
    LEFT JOIN 
        Votes v ON t.PostId = v.PostId
    LEFT JOIN 
        Comments c ON t.PostId = c.PostId
    LEFT JOIN 
        unnest(string_to_array(t.Title, ' ')) AS Tag ON Tag IS NOT NULL
    GROUP BY 
        t.PostId, t.Title, t.CreationDate, t.Score, t.ViewCount, t.AnswerCount
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CommentCount,
    pm.AvgVotes,
    pm.Tags
FROM 
    PostMetrics pm
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;
