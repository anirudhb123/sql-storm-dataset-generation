WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(v_up.VoteCount, 0) AS UpVotes,
        COALESCE(v_down.VoteCount, 0) AS DownVotes
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount 
        FROM Votes 
        WHERE VoteTypeId = 2 -- UpMod
        GROUP BY PostId
    ) v_up ON p.Id = v_up.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount 
        FROM Votes 
        WHERE VoteTypeId = 3 -- DownMod
        GROUP BY PostId
    ) v_down ON p.Id = v_down.PostId
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount
    FROM Comments c
    WHERE c.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY c.PostId
),
PostDetails AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        rc.CommentCount,
        (rp.UpVotes - rp.DownVotes) AS NetScore,
        CASE
            WHEN rp.ViewCount > 1000 THEN 'Highly Viewed'
            WHEN rp.ViewCount BETWEEN 500 AND 1000 THEN 'Moderately Viewed'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM RankedPosts rp
    LEFT JOIN RecentComments rc ON rp.Id = rc.PostId
    WHERE rp.rn <= 10 -- Selecting only the 10 most recent posts by type
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.CommentCount,
    pd.NetScore,
    pd.EngagementLevel
FROM PostDetails pd
WHERE pd.NetScore > 0
ORDER BY pd.NetScore DESC, pd.CreationDate DESC
LIMIT 20;
