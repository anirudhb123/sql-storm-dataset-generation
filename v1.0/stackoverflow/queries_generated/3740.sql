WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RankedUsers AS (
    SELECT 
        us.*,
        RANK() OVER (ORDER BY us.Reputation DESC) AS ReputationRank,
        ROW_NUMBER() OVER (PARTITION BY us.Reputation > 1000 ORDER BY us.PostCount DESC) AS HighReputationRank
    FROM 
        UserStatistics us
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.PostCount,
    ru.AnswerCount,
    ru.UpVotes,
    ru.DownVotes,
    CASE 
        WHEN ru.ReputationRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType,
    COALESCE(NULLIF(ru.UpVotes - ru.DownVotes, 0), 'No Votes') AS NetVotingStatus
FROM 
    RankedUsers ru
WHERE 
    ru.PostCount > 5
    AND ru.AnswerCount > 0
ORDER BY 
    ru.Reputation DESC, 
    ru.PostCount DESC;

-- This query retrieves users with significant post activity and calculates various statistics,
-- ranks them based on their reputation, and categorizes them as contributors while handling NULL logic effectively.
