WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
MaxVotes AS (
    SELECT 
        p.Id,
        MAX(v.VoteTypeId) AS MaxVoteTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        v.VoteTypeId IS NOT NULL
    GROUP BY 
        p.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    CASE 
        WHEN mp.MaxVoteTypeId = 2 THEN 'Most UpVoted'
        WHEN mp.MaxVoteTypeId = 3 THEN 'Most DownVoted'
        ELSE 'Neutral'
    END AS VoteInsight,
    COALESCE(ph.HistoryTypes, 'No history') AS PostHistory,
    COALESCE(ph.LastHistoryDate, 'Never') AS LastHistoryActivity
FROM 
    RankedPosts rp
LEFT JOIN 
    MaxVotes mp ON rp.Id = mp.Id
LEFT JOIN 
    PostHistoryDetails ph ON rp.Id = ph.PostId
WHERE 
    rp.UserRank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 50;
