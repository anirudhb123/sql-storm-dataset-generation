
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        p.AnswerCount,
        p.ViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.AnswerCount, p.ViewCount
)
SELECT 
    tp.Title,
    tp.Score,
    tp.OwnerDisplayName,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.CommentCount,
    pvs.ViewCount,
    COALESCE(CONCAT('Score: ', CAST(tp.Score AS CHAR), ' - Views: ', CAST(pvs.ViewCount AS CHAR)), 'No Activity') AS PostActivity
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteSummary pvs ON tp.PostId = pvs.PostId
ORDER BY 
    tp.Score DESC;
