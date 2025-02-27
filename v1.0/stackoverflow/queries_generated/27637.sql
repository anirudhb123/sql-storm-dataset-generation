WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        -- Create a list of all tags associated with the post
        STRING_AGG(t.TagName, ', ') AS Tags,
        -- Create a list of all users who voted on the post with their vote type
        STRING_AGG(CONCAT(u.DisplayName, ' (', vt.Name, ')'), '; ') AS Votes,
        -- Count the number of comments on the post
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))) )
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only consider Questions
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        rp.Votes,
        rp.CommentCount,
        rp.Rank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 -- Get top 10 questions by score
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Tags,
    tp.Votes,
    tp.CommentCount,
    COALESCE(UPPER(SUBSTRING(tp.Body, 1, 50)), '[No Body Content]') AS PreviewBody,
    COALESCE(SUM(b.Class * b.TagBased), 0) AS TotalBadgePoints
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON b.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.Tags, tp.Votes, tp.CommentCount
ORDER BY 
    tp.Score DESC;
