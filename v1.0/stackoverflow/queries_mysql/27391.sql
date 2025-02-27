
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        u.Reputation AS AuthorReputation,
        p.Tags,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, u.Reputation, p.Tags
),

TagStatistics AS (
    SELECT 
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags,
        AVG(pd.Score) AS AverageScore,
        AVG(pd.ViewCount) AS AverageViewCount
    FROM 
        PostDetails pd
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(pd.Tags, ',', numbers.n), ',', -1)) AS tag 
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
               UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE numbers.n <= CHAR_LENGTH(pd.Tags) - CHAR_LENGTH(REPLACE(pd.Tags, ',', '')) + 1) AS tag ON TRUE
    JOIN 
        Tags t ON tag.tag = t.TagName
    GROUP BY 
        pd.Tags
),

TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Author,
        pd.AuthorReputation,
        pd.CommentCount,
        pd.Upvotes,
        pd.Downvotes,
        pd.Score,
        pd.ViewCount,
        @rownum:=@rownum+1 AS Rank
    FROM 
        PostDetails pd, (SELECT @rownum := 0) r
    ORDER BY 
        pd.Score DESC, pd.CreationDate DESC
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Author,
    tp.AuthorReputation,
    tp.CommentCount,
    tp.Upvotes,
    tp.Downvotes,
    tp.Score,
    tp.ViewCount,
    ts.AverageScore,
    ts.AverageViewCount,
    CONCAT('{ "PostId": ', tp.PostId, ', "Title": "', tp.Title, '" }') AS JsonRepresentation
FROM 
    TopPosts tp
JOIN 
    TagStatistics ts ON TRUE 
WHERE 
    tp.Rank <= 10 
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
