WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS PostRank,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS t(TagName) ON TRUE
    GROUP BY 
        p.Id, pt.Name
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High Repute'
            WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Moderate Repute'
            ELSE 'Low Repute'
        END AS ReputationTier
    FROM 
        Users u
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPostStatistics AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.TagsList,
    ur.Reputation,
    ur.ReputationTier,
    COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
    COALESCE(ps.CloseCount, 0) AS CloseCount,
    COALESCE(ps.ReopenCount, 0) AS ReopenCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    PostVoteStats vs ON vs.PostId = rp.PostId
LEFT JOIN 
    ClosedPostStatistics ps ON ps.PostId = rp.PostId
WHERE 
    (ur.ReputationTier = 'High Repute' OR ur.ReputationTier = 'Moderate Repute')
    AND rp.PostRank <= 5
    AND (TRUE OR rp.ViewCount < 5000 OR rp.CreationDate > NOW() - INTERVAL '30 days')
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
