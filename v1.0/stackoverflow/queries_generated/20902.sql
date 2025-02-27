WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown'
            WHEN u.Reputation > 5000 THEN 'High Reputation'
            WHEN u.Reputation BETWEEN 1000 AND 5000 THEN 'Moderate Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM Users u
),

PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.PostTypeId
),

RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.PostTypeId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.TotalViews,
        RANK() OVER (PARTITION BY ps.PostTypeId ORDER BY ps.TotalViews DESC, ps.UpVoteCount DESC) AS PostRank
    FROM PostStatistics ps
),

FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.PostRank <= 5 THEN 'Top Posts'
            ELSE 'Other Posts'
        END AS PostGroup
    FROM RankedPosts rp
    WHERE rp.UpVoteCount > 10 OR rp.CommentCount > 5
)

SELECT 
    up.UserId,
    up.Reputation,
    up.ReputationCategory,
    fp.PostId,
    fp.PostTypeId,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.TotalViews,
    fp.PostGroup
FROM UserReputation up
LEFT JOIN FilteredPosts fp ON up.UserId IN (
    SELECT DISTINCT OwnerUserId 
    FROM Posts 
    WHERE CreationDate >= NOW() - INTERVAL '1 year'
)
WHERE up.Reputation IS NOT NULL 
ORDER BY up.Reputation DESC, fp.TotalViews DESC;
