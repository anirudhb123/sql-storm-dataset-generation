WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.Views,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        MAX(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted' ELSE 'Not Accepted' END) AS AcceptedStatus,
        ARRAY_AGG(t.TagName) AS TagsList
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><') AS t(TagName) ON true -- Unnesting tags
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)  -- 10 = Closed, 11 = Reopened
    GROUP BY ph.PostId
),
FinalPostDetails AS (
    SELECT 
        pd.*, 
        cp.CloseCount,
        cp.LastClosedDate
    FROM PostDetails pd
    LEFT JOIN ClosedPosts cp ON pd.PostId = cp.PostId
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.Views,
    fp.CommentCount,
    fp.AcceptedStatus,
    COALESCE(fp.CloseCount, 0) AS CloseCount,
    COALESCE(fp.LastClosedDate, 'No closures') AS LastClosedDate,
    fp.TagsList
FROM UserReputation ur
JOIN FinalPostDetails fp ON ur.UserId = fp.OwnerUserId
WHERE ur.ReputationRank <= 10
ORDER BY ur.Reputation DESC, fp.Score DESC
LIMIT 20;
