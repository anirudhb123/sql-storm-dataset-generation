WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        DisplayName,
        0 AS Level
    FROM Users
    WHERE Reputation > 0
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        ur.Level + 1
    FROM Users u
    JOIN UserReputation ur ON u.Id = ur.Id
    WHERE ur.Level < 5
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title
),
ClosedQuestions AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
),
UserBadgeSummary AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
FinalSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ur.Reputation,
        COALESCE(ubs.TotalBadges, 0) AS TotalBadges,
        COALESCE(SUM(ps.UpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(ps.DownVotes), 0) AS TotalDownVotes,
        COALESCE(COUNT(DISTINCT cq.Id), 0) AS ClosedQuestionsCount
    FROM Users u
    LEFT JOIN UserReputation ur ON u.Id = ur.Id
    LEFT JOIN PostVoteSummary ps ON u.Id = ps.PostId
    LEFT JOIN UserBadgeSummary ubs ON u.Id = ubs.UserId
    LEFT JOIN ClosedQuestions cq ON u.Id = cq.ClosedBy
    GROUP BY u.Id, u.DisplayName, ur.Reputation
)
SELECT 
    fs.UserId,
    fs.DisplayName,
    fs.Reputation,
    fs.TotalBadges,
    fs.TotalUpVotes,
    fs.TotalDownVotes,
    fs.ClosedQuestionsCount
FROM FinalSummary fs
WHERE fs.Reputation >= (SELECT AVG(Reputation) FROM Users)
ORDER BY fs.Reputation DESC
LIMIT 50;
