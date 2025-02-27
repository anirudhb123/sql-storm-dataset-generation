WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Last year
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerName,
        Score,
        CreationDate,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10 -- Top 10 questions by score
)
SELECT 
    tp.*,
    json_agg(DISTINCT t.TagName) AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(p.Tags, ',')) AS TagName
        FROM 
            Posts p
        WHERE 
            p.Id = tp.PostId
    ) t ON true
GROUP BY 
    tp.PostId
ORDER BY 
    tp.Score DESC;
