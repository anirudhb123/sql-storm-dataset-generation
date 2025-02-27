WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        P.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
),
RecentUserVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        u.Reputation,
        RANK() OVER (PARTITION BY v.PostId ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Votes v
    INNER JOIN 
        Users u ON u.Id = v.UserId
    WHERE 
        u.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    AND 
        v.VoteTypeId IN (2, 3)  --Considering only UpVote and DownVote
),
PostVoteSummary AS (
    SELECT 
        rp.PostId,
        SUM(CASE WHEN rv.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN rv.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentUserVotes rv ON rv.PostId = rp.PostId
    GROUP BY 
        rp.PostId
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS PostHistoryTypes,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ph.UpVotes,
    ph.DownVotes,
    ph.PostHistoryTypes,
    COALESCE(DENSE_RANK() OVER (ORDER BY rp.CreationDate DESC), 0) AS RecentPostRank,
    CASE 
        WHEN ph.UpVotes > ph.DownVotes THEN 'More Upvotes'
        WHEN ph.UpVotes < ph.DownVotes THEN 'More Downvotes'
        ELSE 'Equal Votes'
    END AS VoteComparison,
    CASE 
        WHEN ph.LastHistoryDate IS NOT NULL AND ph.LastHistoryDate < CURRENT_TIMESTAMP - INTERVAL '90 days' THEN 'Needs Attention'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteSummary ph ON ph.PostId = rp.PostId
LEFT JOIN 
    PostHistoryInfo phi ON phi.PostId = rp.PostId
WHERE 
    rp.Rank <= 5  -- Limit to top 5 posts by type
ORDER BY 
    rp.CreationDate DESC;
