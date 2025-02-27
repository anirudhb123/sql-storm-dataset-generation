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
        p.CreationDate >= NOW() - INTERVAL '1 year'
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
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
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
        p.Id
)
SELECT 
    tp.Title,
    tp.Score,
    tp.OwnerDisplayName,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.CommentCount,
    pvs.ViewCount,
    COALESCE(CONCAT('Score: ', CAST(tp.Score AS VARCHAR), ' - Views: ', CAST(pvs.ViewCount AS VARCHAR)), 'No Activity') AS PostActivity
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteSummary pvs ON tp.PostId = pvs.PostId
ORDER BY 
    tp.Score DESC NULLS LAST

