WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1 AND  -- Only questions
        p.CreationDate > NOW() - INTERVAL '1 year'  -- Only posts from the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score, 
        rp.Tags,
        u.DisplayName AS OwnerName,
        u.Reputation AS OwnerReputation,
        COUNT(v.Id) AS UpVotes
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Upvotes
    WHERE 
        rp.RankScore <= 10  -- Get top 10 posts
    GROUP BY 
        rp.PostId, u.DisplayName, u.Reputation
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Tags,
    tp.OwnerName,
    tp.OwnerReputation,
    tp.UpVotes,
    COALESCE(ph.Comment, 'No changes') AS MostRecentChange
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId 
WHERE 
    ph.CreationDate = (
        SELECT 
            MAX(CreationDate) 
        FROM 
            PostHistory 
        WHERE 
            PostId = tp.PostId
    )
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
