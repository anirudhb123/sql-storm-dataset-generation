WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1  -- Only Questions
),
TopTenPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostSummary AS (
    SELECT 
        tp.Title,
        tp.ViewCount,
        tp.Score,
        tp.AnswerCount,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        TopTenPosts tp
    LEFT JOIN 
        Comments c ON c.PostId = tp.PostId
    LEFT JOIN 
        STRING_TO_ARRAY(tp.Tags, ',') AS tags ON t.TagName = TRIM(tags.value)
    GROUP BY 
        tp.Title, tp.ViewCount, tp.Score, tp.AnswerCount
)
SELECT 
    p.Title,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    p.Tags,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM 
    PostSummary p
ORDER BY 
    p.ViewCount DESC, p.Score DESC
LIMIT 10;
