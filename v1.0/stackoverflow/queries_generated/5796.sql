WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 4)  -- Upvotes and Offensive votes
    WHERE 
        p.PostTypeId = 1  -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopRankedPosts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS RowNum
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10  -- Top 10 posts based on score
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.CommentCount,
    trp.VoteCount,
    u.DisplayName AS UserName,
    u.Reputation AS UserReputation
FROM 
    TopRankedPosts trp
JOIN 
    Users u ON trp.OwnerUserId = u.Id
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC;
