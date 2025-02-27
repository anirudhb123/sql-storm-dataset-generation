WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(v.CreationDate), '1900-01-01') AS LastVoteDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Consider only posts from the last year
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body, 
        rp.ViewCount, 
        rp.Score, 
        rp.CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Tags t ON rp.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        rp.PostRank <= 3 -- Only keep the top 3 posts per user
    GROUP BY 
        rp.PostId
),
HighScoringPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        ViewCount, 
        Score, 
        CommentCount, 
        TagList
    FROM 
        TopPosts
    WHERE 
        Score > 10 -- Only high-scoring posts
)
SELECT 
    hp.PostId,
    hp.Title,
    hp.Body,
    hp.ViewCount,
    hp.Score,
    hp.CommentCount,
    hp.TagList,
    u.DisplayName AS OwnerDisplayName,
    COUNT(b.Id) AS BadgeCount,
    MAX(b.Class) AS HighestBadgeClass -- Get the highest badge class owned by the user
FROM 
    HighScoringPosts hp
JOIN 
    Users u ON hp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    hp.PostId, u.DisplayName
ORDER BY 
    hp.Score DESC, hp.ViewCount DESC;
