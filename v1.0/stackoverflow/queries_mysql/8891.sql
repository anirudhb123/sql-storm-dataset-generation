
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.PostTypeId, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Owner,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Owner,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    CONCAT('Total Score: ', (tp.UpVotes - tp.DownVotes)) AS ScoreSummary
FROM 
    TopPosts tp
ORDER BY 
    tp.UpVotes DESC, tp.CommentCount DESC;
