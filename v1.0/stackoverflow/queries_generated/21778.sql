WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(*) OVER (PARTITION BY pt.Name) AS TotalPosts,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    AND 
        p.ViewCount > 0
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ScoreRank,
        rp.TotalPosts,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.ScoreRank <= 3 THEN 'Top 3'
            ELSE 'Others'
        END AS RankGroup,
        (rp.UpVotes - rp.DownVotes) AS NetVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount
    FROM 
        RankedPosts rp
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.Score,
    pd.RankGroup,
    pd.TotalPosts,
    pd.NetVotes,
    COALESCE(cpr.CloseReasons, 'Not Closed') AS CloseReasons,
    pd.CommentCount,
    EXTRACT(EPOCH FROM (NOW() - p.CreationDate)) AS AgeInSeconds
FROM 
    PostDetails pd
LEFT JOIN 
    ClosedPostReasons cpr ON pd.PostId = cpr.PostId
ORDER BY 
    pd.Score DESC, 
    pd.CommentCount DESC
LIMIT 50;
