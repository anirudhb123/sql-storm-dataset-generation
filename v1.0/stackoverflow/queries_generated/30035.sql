WITH RecursivePostCTE AS (
    SELECT p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.AcceptedAnswerId, 1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT a.Id, a.Title, a.CreationDate, a.OwnerUserId, a.AcceptedAnswerId, rp.Level + 1
    FROM Posts a
    INNER JOIN RecursivePostCTE rp ON a.ParentId = rp.Id
    WHERE a.PostTypeId = 2 -- Answers only
),
UserReputation AS (
    SELECT u.Id, u.DisplayName, u.Reputation,
           ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    WHERE u.Reputation IS NOT NULL
),
LatestPostChanges AS (
    SELECT p.Id AS PostId, ph.PostHistoryTypeId, ph.CreationDate, 
           ph.UserDisplayName, ph.Comment,
           DENSE_RANK() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS ChangeRank
    FROM PostHistory ph
    INNER JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
)
SELECT 
    rp.Id AS QuestionId,
    rp.Title AS QuestionTitle,
    rp.CreationDate AS QuestionCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    uR.ReputationRank,
    COALESCE(lpc.Comment, 'No recent changes') AS LastChangeComment,
    COALESCE(lpc.CreationDate, 'No changes recorded') AS LastChangeDate,
    
    -- Calculating the number of answers
    (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = rp.Id AND a.PostTypeId = 2) AS AnswerCount,

    -- Handling potential NULL for AcceptedAnswerId via CASE
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL 
            THEN (SELECT Title FROM Posts WHERE Id = rp.AcceptedAnswerId)
        ELSE 'No accepted answer'
    END AS AcceptedAnswerTitle,

    -- Aggregate function to find total comments on the question
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.Id) AS TotalComments

FROM RecursivePostCTE rp
INNER JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN LatestPostChanges lpc ON lpc.PostId = rp.Id AND lpc.ChangeRank = 1
LEFT JOIN UserReputation uR ON u.Id = uR.Id
WHERE u.Reputation > 1000
ORDER BY OwnerReputation DESC, AnswerCount DESC;

