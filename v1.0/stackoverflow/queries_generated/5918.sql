WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.Reputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Filter only questions
        AND p.CreationDate > NOW() - INTERVAL '1 year' -- Only consider posts from the last year
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        Reputation
    FROM 
        RankedPosts
    WHERE 
        Rank <= 3 -- Get top 3 posts per user
)
SELECT 
    t.Title,
    t.Score,
    t.ViewCount,
    t.CreationDate,
    u.DisplayName,
    u.Reputation,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2::smallint) AS UpVotes,
    SUM(v.VoteTypeId = 3::smallint) AS DownVotes
FROM 
    TopPosts t
LEFT JOIN 
    Users u ON t.Reputation = u.Reputation
LEFT JOIN 
    Comments c ON t.PostId = c.PostId
LEFT JOIN 
    Votes v ON t.PostId = v.PostId
GROUP BY 
    t.PostId, t.Title, t.Score, t.ViewCount, t.CreationDate, u.DisplayName, u.Reputation
ORDER BY 
    t.Score DESC, t.ViewCount DESC;
