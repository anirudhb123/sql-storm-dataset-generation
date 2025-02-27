WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Counting upvotes
        SUM(v.VoteTypeId = 3) AS DownVotes -- Counting downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, ViewCount, Score, Tags, CommentCount, UpVotes, DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5  -- Top 5 posts for each user
)
SELECT 
    u.DisplayName,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
FROM 
    Users u
JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId
LEFT JOIN 
    LATERAL string_to_array(substring(tp.Tags, 2, length(tp.Tags)-2), '><') AS tag ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag
GROUP BY 
    u.DisplayName, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.CommentCount, tp.UpVotes, tp.DownVotes
ORDER BY 
    u.DisplayName, tp.Score DESC;
