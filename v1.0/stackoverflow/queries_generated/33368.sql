WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        p.OwnerUserId,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Starting with Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        p.OwnerUserId,
        rp.Level + 1
    FROM Posts p
    JOIN RecursivePosts rp ON p.ParentId = rp.Id
),
PostScores AS (
    SELECT 
        rp.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS Score,
        COUNT(c.Id) AS CommentCount
    FROM RecursivePosts rp
    LEFT JOIN Votes v ON rp.Id = v.PostId
    LEFT JOIN Comments c ON rp.Id = c.PostId
    GROUP BY rp.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostHistoryAggregate AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastEdited
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)
SELECT 
    rp.Title AS QuestionTitle,
    us.DisplayName AS UserDisplayName,
    us.Reputation AS UserReputation,
    ps.Score AS TotalScore,
    ps.VoteCount AS TotalVotes,
    ps.CommentCount AS TotalComments,
    pha.HistoryTypes AS PostHistory,
    pha.LastEdited AS LastEditedDate,
    COUNT(DISTINCT ans.Id) AS AnswerCount
FROM RecursivePosts rp
JOIN UserReputation us ON rp.OwnerUserId = us.UserId 
JOIN PostScores ps ON rp.Id = ps.PostId
LEFT JOIN Posts ans ON rp.Id = ans.ParentId AND ans.PostTypeId = 2
LEFT JOIN PostHistoryAggregate pha ON rp.Id = pha.PostId
WHERE rp.Level = 0 -- Filter to only show questions at the top level
GROUP BY 
    rp.Title, 
    us.DisplayName, 
    us.Reputation,
    ps.Score, 
    ps.VoteCount,
    ps.CommentCount,
    pha.HistoryTypes,
    pha.LastEdited
ORDER BY ps.Score DESC, rp.CreationDate DESC;
