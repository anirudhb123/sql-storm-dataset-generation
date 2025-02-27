
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.Reputation AS OwnerReputation,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER(PARTITION BY p.Id) AS CommentCount
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Votes v
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        ph.UserDisplayName AS ClosedBy,
        GROUP_CONCAT(DISTINCT pht.Name ORDER BY pht.Name ASC SEPARATOR ', ') AS CloseReasons
    FROM
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY
        ph.PostId, ph.UserDisplayName
),
FinalPostStats AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerReputation,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes,
        COALESCE(closed.CloseReasons, 'Not Closed') AS CloseReasons,
        rp.CommentCount,
        CASE 
            WHEN rp.RankByScore <= 5 THEN 'Top Performer'
            ELSE 'Regular Performer'
        END AS PerformanceCategory
    FROM
        RankedPosts rp
    LEFT JOIN
        PostVoteStats pvs ON rp.PostId = pvs.PostId
    LEFT JOIN
        ClosedPosts closed ON rp.PostId = closed.PostId
)
SELECT 
    f.Title,
    f.OwnerReputation,
    f.UpVotes,
    f.DownVotes,
    f.CommentCount,
    f.CloseReasons,
    (f.UpVotes - f.DownVotes) AS NetVotes,
    CASE 
        WHEN (f.UpVotes - f.DownVotes) > 10 THEN 'Highly Engaged'
        WHEN (f.UpVotes - f.DownVotes) BETWEEN 1 AND 10 THEN 'Moderately Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM 
    FinalPostStats f
WHERE 
    f.CommentCount > 0 
    AND f.OwnerReputation IS NOT NULL
ORDER BY 
    f.CreationDate DESC
LIMIT 30 OFFSET 0;
