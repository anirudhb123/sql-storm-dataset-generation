
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagsList,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(v.Id) * (v.VoteTypeId = 2) AS UpVotes,  
        COUNT(v.Id) * (v.VoteTypeId = 3) AS DownVotes   
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.AnswerCount,
        ps.CommentCount,
        ps.TagsList,
        ps.UpVotes,
        ps.DownVotes,
        @row_num := @row_num + 1 AS Rank
    FROM 
        PostStatistics ps, (SELECT @row_num := 0) AS r
    ORDER BY 
        ps.Score DESC, ps.ViewCount DESC
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.TagsList,
    tp.UpVotes,
    tp.DownVotes,
    CASE 
        WHEN tp.UpVotes > tp.DownVotes THEN 'Positive'
        WHEN tp.UpVotes < tp.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10  
ORDER BY 
    tp.Rank;
