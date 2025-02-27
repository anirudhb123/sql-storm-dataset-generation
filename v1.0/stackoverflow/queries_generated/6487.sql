WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only questions
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.RankByScore <= 10 -- Top 10 questions by score
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    LEFT JOIN 
        Posts p ON tp.PostId = p.Id
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        tp.PostId
)
SELECT 
    pd.*,
    json_agg(DISTINCT b.Name) AS Badges
FROM 
    PostDetails pd
LEFT JOIN 
    Badges b ON pd.OwnerUserId = b.UserId
WHERE 
    b.Date >= NOW() - INTERVAL '6 months' -- Badges awarded in the last 6 months
GROUP BY 
    pd.PostId
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
