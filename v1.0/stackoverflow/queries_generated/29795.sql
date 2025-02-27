WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName 
        AS T ON T.TagName IS NOT NULL
    WHERE 
        p.PostTypeId IN (1, 2)  -- Questions and Answers
    GROUP BY 
        p.Id, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate, 
        ViewCount, 
        Score, 
        AnswerCount, 
        CommentCount, 
        OwnerDisplayName, 
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5  -- Get Top 5 posts based on score for each post type
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.ViewCount,
    COALESCE(tp.Score, 0) AS Score,
    tp.AnswerCount,
    tp.CommentCount,
    tp.OwnerDisplayName,
    tp.Tags,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = tp.PostId) AS TotalComments,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = tp.PostId AND V.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = tp.PostId AND V.VoteTypeId = 3) AS DownVotes
FROM 
    TopPosts tp
ORDER BY 
    tp.CreationDate DESC  -- Order by the most recent posts
LIMIT 100;  -- Limit the number of results to 100
