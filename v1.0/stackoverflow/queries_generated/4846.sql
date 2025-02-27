WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        TRIM(REGEXP_REPLACE(p.Tags, '(<([^>]+)>|[^a-zA-Z0-9\s])', '', 'g')) AS CleanedTags
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    AND p.OwnerUserId IS NOT NULL
),
CommentsCount AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM Comments c
    GROUP BY c.PostId
),
VotesSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Votes v
    GROUP BY v.PostId
)
SELECT 
    u.DisplayName,
    p.Title,
    COALESCE(cc.TotalComments, 0) AS TotalComments,
    COALESCE(vs.TotalUpVotes, 0) AS UpVotes,
    COALESCE(vs.TotalDownVotes, 0) AS DownVotes,
    u.Reputation,
    ut.ReputationRank
FROM PostsWithTags p
JOIN UserReputation ut ON p.OwnerUserId = ut.UserId
LEFT JOIN CommentsCount cc ON p.PostId = cc.PostId
LEFT JOIN VotesSummary vs ON p.PostId = vs.PostId
WHERE 
    (ut.Reputation >= 500 OR cc.TotalComments > 10)
    AND p.CleanedTags LIKE '%SQL%'
ORDER BY 
    CASE 
        WHEN ut.Reputation >= 1000 THEN 1
        WHEN ut.Reputation >= 500 THEN 2
        ELSE 3
    END,
    TotalComments DESC
LIMIT 50;
