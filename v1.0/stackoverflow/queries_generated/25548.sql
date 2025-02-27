WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        u.DisplayName AS Author,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR CHAR_LENGTH(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        Tags,
        Author,
        Upvotes,
        Downvotes,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10  -- Top 10 questions based on score
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.Tags,
    tp.Author,
    tp.Upvotes,
    tp.Downvotes,
    (tp.Upvotes - tp.Downvotes) AS VoteBalance,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT ph.Id) AS EditHistoryCount
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON c.PostId = tp.PostId
LEFT JOIN 
    PostHistory ph ON ph.PostId = tp.PostId AND ph.PostHistoryTypeId IN (4, 5, 6, 12)  -- Edits and deletions
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.Score, tp.ViewCount, tp.Tags, tp.Author, tp.Upvotes, tp.Downvotes
ORDER BY 
    VoteBalance DESC, tp.Score DESC;
