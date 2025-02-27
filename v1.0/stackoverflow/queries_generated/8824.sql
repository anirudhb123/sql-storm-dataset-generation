WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 AND -- Only Questions
        p.CreationDate > NOW() - INTERVAL '1 YEAR' -- Last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        PostRank = 1
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    trp.OwnerDisplayName,
    trp.CommentCount,
    trp.AnswerCount,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = trp.PostId 
        AND v.VoteTypeId IN (2,3) -- Counting upvotes and downvotes
    ) AS VoteCount
FROM 
    TopRankedPosts trp
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
