WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Only questions
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY u.Id, u.Reputation
),
RecentVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastCloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ur.Reputation,
    ur.QuestionCount,
    ur.TotalScore,
    ur.TotalViews,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COALESCE(rv.UpVotes, 0) AS UpVotes,
    COALESCE(rv.DownVotes, 0) AS DownVotes,
    COALESCE(ph.LastCloseDate, 'Never Closed') AS LastCloseDate,
    COALESCE(ph.LastReopenDate, 'Never Reopened') AS LastReopenDate,
    ph.CloseReopenCount
FROM Users u
JOIN UserReputation ur ON u.Id = ur.UserId
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN RecentVotes rv ON p.Id = rv.PostId
LEFT JOIN PostHistoryDetails ph ON p.Id = ph.PostId
WHERE ur.Reputation > 1000 -- Only users with reputation greater than 1000
GROUP BY u.Id, u.DisplayName, ur.Reputation, ur.QuestionCount, ur.TotalScore, ur.TotalViews, rv.UpVotes, rv.DownVotes, ph.LastCloseDate, ph.LastReopenDate, ph.CloseReopenCount
ORDER BY ur.Reputation DESC, TotalPosts DESC;
