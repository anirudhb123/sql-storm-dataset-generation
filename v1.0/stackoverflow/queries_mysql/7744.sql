
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SELECT COUNT(*) FROM Posts AS a WHERE a.AcceptedAnswerId = p.Id) AS AcceptedAnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
RankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.AcceptedAnswerCount,
        @row_number := @row_number + 1 AS PostRank
    FROM 
        RecentPosts rp, (SELECT @row_number := 0) AS rn
    ORDER BY 
        rp.Score DESC, rp.CommentCount DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.AcceptedAnswerCount,
    rp.PostRank
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 10
ORDER BY 
    rp.PostRank;
