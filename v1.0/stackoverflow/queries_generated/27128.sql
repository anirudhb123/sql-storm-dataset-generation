WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Within the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.Tags
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
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        rn = 1 -- Get the latest version of each post
    ORDER BY 
        Score DESC, ViewCount DESC
    LIMIT 10
)
SELECT
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount,
    ARRAY(SELECT DISTINCT UNNEST(string_to_array(tp.Tags, '><')) AS Tag) AS ParsedTags,
    (SELECT STRING_AGG(DISTINCT CONCAT(u.DisplayName, ' (Reputation: ', u.Reputation, ')'), ', ')
     FROM Users u
     WHERE u.Id IN (SELECT DISTINCT c.UserId FROM Comments c WHERE c.PostId = tp.PostId)) AS Commenters
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC;
