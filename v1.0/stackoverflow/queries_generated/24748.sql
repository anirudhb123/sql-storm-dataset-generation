WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS CloseCount,
        COUNT(DISTINCT CASE WHEN b.Id IS NOT NULL THEN b.Id END) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Location IS NOT NULL
),
PostMetrics AS (
    SELECT 
        ps.PostId,
        ps.TotalComments,
        ps.UpVotes,
        ps.DownVotes,
        ps.CloseCount,
        ur.ReputationRank,
        ur.Reputation,
        CASE 
            WHEN ps.CloseCount > 0 THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        PostStats ps
    JOIN 
        UserReputation ur ON ps.OwnerUserId = ur.UserId
)
SELECT 
    pm.PostId,
    pm.TotalComments,
    pm.UpVotes,
    pm.DownVotes,
    CASE 
        WHEN pm.UpVotes > pm.DownVotes THEN 'Positive'
        WHEN pm.UpVotes < pm.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    pm.ReputationRank,
    pm.Reputation,
    pm.PostStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PostMetrics pm
LEFT JOIN 
    Posts p ON pm.PostId = p.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(p.Tags, ',')) AS TagName
    ) AS t ON true
WHERE 
    (pm.PostStatus = 'Active' AND pm.ReputationRank <= 10) OR 
    (pm.PostStatus = 'Closed' AND pm.ReputationRank >= 20)
GROUP BY 
    pm.PostId, pm.TotalComments, pm.UpVotes, pm.DownVotes, 
    pm.ReputationRank, pm.Reputation, pm.PostStatus
ORDER BY 
    pm.TotalComments DESC, pm.UpVotes DESC;
