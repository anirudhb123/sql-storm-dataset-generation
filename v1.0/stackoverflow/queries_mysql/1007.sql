
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_owner_user_id := p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id,
        (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS init
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    ORDER BY 
        p.OwnerUserId, p.Score DESC, p.CreationDate DESC
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),
PostVoteSummary AS (
    SELECT 
        p.Id,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
CommentStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    tp.Id,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerName,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE(pvs.TotalBounty, 0) AS TotalBounty,
    COALESCE(cs.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN COALESCE(pvs.UpVotes, 0) > COALESCE(pvs.DownVotes, 0) THEN 'Positive'
        WHEN COALESCE(pvs.UpVotes, 0) < COALESCE(pvs.DownVotes, 0) THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteSummary pvs ON tp.Id = pvs.Id
LEFT JOIN 
    CommentStats cs ON tp.Id = cs.PostId
ORDER BY 
    tp.Score DESC;
