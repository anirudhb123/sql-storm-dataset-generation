
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        STRING_AGG(t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS TagsList,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,  
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes   
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' + t.TagName + '%'
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
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
        ROW_NUMBER() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS Rank
    FROM 
        PostStatistics ps
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
