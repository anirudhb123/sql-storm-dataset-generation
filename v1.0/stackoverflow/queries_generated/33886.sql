WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
UserReputationSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId, 
        ph.UserId, 
        ph.CreationDate,
        pht.Name AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ActionRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days' -- Actions in the last 30 days
)
SELECT 
    r.Title,
    r.CreationDate AS LastQuestionDate,
    r.Score AS QuestionScore,
    r.ViewCount AS QuestionViewCount,
    ur.DisplayName AS UserName,
    ur.Reputation AS UserReputation,
    ur.NetVotes AS UserNetVotes,
    ur.QuestionCount AS UserQuestionCount,
    ph.HistoryType AS RecentAction,
    ph.CreationDate AS ActionDate
FROM 
    RankedPosts r
JOIN 
    Users ur ON r.PostId = ur.Id
LEFT JOIN 
    PostHistoryCTE ph ON r.PostId = ph.PostId AND ph.ActionRank = 1 -- Most recent action
WHERE 
    ur.Reputation > 1000 -- Only users with reputation > 1000
    AND r.Rank = 1 -- Latest question per user
ORDER BY 
    r.CreationDate DESC
LIMIT 50;
