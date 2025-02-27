WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpvoteCount  -- counting only upvotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2)  -- only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.PostRank <= 5  -- Top 5 posts per user
    ORDER BY 
        rp.OwnerDisplayName, rp.Score DESC
)
SELECT 
    fp.OwnerDisplayName,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.CommentCount,
    fp.UpvoteCount
FROM 
    FilteredPosts fp
JOIN 
    Badges b ON fp.OwnerDisplayName = b.UserId
WHERE 
    b.Class = 1  -- Only Gold badges
ORDER BY 
    fp.ViewCount DESC, fp.Score DESC;
