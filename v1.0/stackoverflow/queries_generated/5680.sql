WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND -- only questions
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days' -- within the last 30 days
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top 10'
        WHEN rp.Rank <= 50 THEN 'Top 50'
        ELSE 'Below 50'
    END AS RankCategory
FROM 
    RankedPosts rp
WHERE 
    rp.Score > 10 -- Filter for higher scored posts
ORDER BY 
    rp.Rank;
