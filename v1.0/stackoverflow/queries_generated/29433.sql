WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,  -- Upvotes
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,  -- Downvotes
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts in the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5  -- Top 5 posts per tag
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    u.DisplayName AS OwnerName,
    u.Reputation AS OwnerReputation,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    ph.Comment AS LastActivityComment,
    ph.CreationDate AS LastActivityDate
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId 
    AND ph.CreationDate = (
        SELECT MAX(CreationDate) 
        FROM PostHistory 
        WHERE PostId = tp.PostId
    )
LEFT JOIN 
    unnest(string_to_array(tp.Tags, ',')) AS t(TagName)
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.CommentCount, tp.UpVoteCount, 
    tp.DownVoteCount, u.DisplayName, u.Reputation, ph.Comment, ph.CreationDate
ORDER BY 
    tp.UpVoteCount DESC, 
    tp.CommentCount DESC;
