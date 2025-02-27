WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON t.WikiPostId = p.Id OR t.ExcerptPostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.Tags 
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 -- Get the latest post for each user
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        (SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) -
         SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END)) AS ReputationScore -- Upvotes minus downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.UserId,
    up.DisplayName,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    up.ReputationScore,
    STRING_AGG(DISTINCT tg.TagName, ', ') AS TagList
FROM 
    UserScores up
JOIN 
    TopPosts tp ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    UNNEST(tp.Tags) AS tg(TagName)
GROUP BY 
    up.UserId, up.DisplayName, tp.Title, tp.Body, tp.CreationDate, tp.Score, tp.ViewCount, tp.AnswerCount, tp.CommentCount, up.ReputationScore
ORDER BY 
    up.ReputationScore DESC, tp.CreationDate DESC
LIMIT 10;
