WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.Score,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    WHERE 
        p.PostTypeId = 1 AND  -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Questions created in the last year
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.Score
),
TopRankedPosts AS (
    SELECT 
        Id, 
        Title, 
        OwnerName, 
        CreationDate, 
        Score, 
        AnswerCount 
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5  -- Top 5 questions in terms of score
),
VotesSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Votes
    WHERE 
        PostId IN (SELECT Id FROM TopRankedPosts)
    GROUP BY 
        PostId
)
SELECT 
    trp.Title,
    trp.OwnerName,
    trp.CreationDate,
    trp.Score,
    trp.AnswerCount,
    COALESCE(vs.TotalUpvotes, 0) AS TotalUpvotes,
    COALESCE(vs.TotalDownvotes, 0) AS TotalDownvotes
FROM 
    TopRankedPosts trp
LEFT JOIN 
    VotesSummary vs ON trp.Id = vs.PostId
ORDER BY 
    trp.Score DESC, 
    trp.AnswerCount DESC;
