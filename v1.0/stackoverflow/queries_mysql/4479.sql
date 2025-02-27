
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        @row_num := IF(@prev_user = p.OwnerUserId, @row_num + 1, 1) AS Rank,
        @prev_user := p.OwnerUserId,
        COALESCE(u.Reputation, 0) AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_num := 0, @prev_user := '') AS init
    WHERE 
        p.CreationDate > DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
    ORDER BY 
        p.OwnerUserId, p.ViewCount DESC
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.ViewCount,
        rp.OwnerReputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerReputation,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(pvs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvs.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN pc.CommentCount IS NULL THEN 'No Comments'
        ELSE 'Has Comments'
    END AS CommentStatus,
    CASE 
        WHEN tp.OwnerReputation >= 500 THEN 'High Reputation'
        WHEN tp.OwnerReputation >= 100 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationLevel
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
LEFT JOIN 
    PostVoteSummary pvs ON tp.PostId = pvs.PostId
ORDER BY 
    tp.ViewCount DESC;
