WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        ScoreRank,
        ViewRank
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10 OR ViewRank <= 10
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    pp.AnswerCount,
    pp.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    b.Name AS BadgeName
FROM 
    TopPosts pp
JOIN 
    Users u ON pp.PostId IN (SELECT OwnerUserId FROM Posts WHERE Id = pp.PostId)
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC;
