WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Count upvotes and downvotes
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.VoteCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY rp.Score DESC, rp.CommentCount DESC) AS OverallRank
    FROM 
        RankedPosts rp
    JOIN 
        Users U ON rp.OwnerUserId = U.Id
    WHERE 
        rp.UserRank <= 5 -- Top 5 posts per user
)
SELECT 
    tp.Id,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.VoteCount,
    tp.OwnerDisplayName,
    tp.Reputation,
    tp.OverallRank
FROM 
    TopPosts tp
WHERE 
    tp.OverallRank <= 50 -- Limit to top 50 posts overall
ORDER BY 
    tp.OverallRank;
