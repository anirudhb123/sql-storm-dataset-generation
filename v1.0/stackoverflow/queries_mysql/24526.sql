
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
PostAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
        LEFT JOIN PostHistory ph ON p.Id = ph.PostId 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.AcceptedAnswerId
),
ClosePostReasons AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(cr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        Posts p 
        LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
        LEFT JOIN CloseReasonTypes cr ON CAST(ph.Comment AS UNSIGNED) = cr.Id
    WHERE 
        ph.Comment IS NOT NULL
    GROUP BY 
        p.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(pa.CommentCount) AS TotalComments,
        SUM(pa.UpVotesCount) AS TotalUpVotes,
        SUM(pa.DownVotesCount) AS TotalDownVotes,
        SUM(CASE WHEN pa.CommentCount > 0 THEN 1 ELSE 0 END) AS ActivePostsCount
    FROM 
        Users u
        INNER JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN PostAnalysis pa ON p.Id = pa.PostId
    GROUP BY 
        u.Id
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationRank,
    ups.PostsCount,
    ups.TotalComments,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    ups.ActivePostsCount,
    COALESCE(cpr.CloseReasons, 'None') AS CloseReasons
FROM 
    UserReputation ur
    LEFT JOIN UserPostStats ups ON ur.UserId = ups.UserId
    LEFT JOIN ClosePostReasons cpr ON ups.UserId = cpr.PostId
WHERE 
    ur.Reputation > (
        SELECT AVG(Reputation) FROM UserReputation
    ) 
    AND ur.CreationDate < '2023-10-01 12:34:56' - INTERVAL 1 YEAR
ORDER BY 
    ur.Reputation DESC, 
    ups.PostsCount DESC
LIMIT 50;
