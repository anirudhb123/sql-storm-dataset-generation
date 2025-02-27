WITH LatestPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostVoteStats AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostWithVotes AS (
    SELECT 
        lp.Title,
        lp.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes
    FROM 
        LatestPosts lp
    LEFT JOIN 
        Users u ON lp.OwnerUserId = u.Id
    LEFT JOIN 
        PostVoteStats pvs ON lp.Id = pvs.PostId
    WHERE 
        lp.rn = 1
),
TopPosts AS (
    SELECT 
        *,
        (UpVotes - DownVotes) AS Score
    FROM 
        PostWithVotes
    WHERE 
        UpVotes > 0 OR DownVotes > 0
    ORDER BY 
        Score DESC
    LIMIT 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.UpVotes,
    tp.DownVotes,
    CASE 
        WHEN tp.Score > 0 THEN 'Positive'
        WHEN tp.Score < 0 THEN 'Negative'
        ELSE 'Neutral' 
    END AS ScoreType,
    PHT.Comment AS ClosureReason
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory PHT ON tp.Id = PHT.PostId AND PHT.PostHistoryTypeId = 10
ORDER BY 
    tp.CreationDate DESC;
