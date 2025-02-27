WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        1 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 500

    UNION ALL

    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ur.Level + 1
    FROM 
        Users u
    JOIN 
        UserReputation ur ON u.Reputation > ur.Reputation
    WHERE 
        ur.Level < 5
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(pc.UpVoteCount), 0) AS TotalUpVotes,
        COALESCE(SUM(pc.DownVoteCount), 0) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostVoteCounts pc ON p.Id = pc.PostId
    WHERE 
        u.Reputation >= 1000
    GROUP BY 
        u.Id
),
FilteredUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.PostCount,
        u.TotalUpVotes,
        u.TotalDownVotes,
        (u.TotalUpVotes - u.TotalDownVotes) AS NetVotes
    FROM 
        UserPostStats u
    WHERE 
        u.PostCount > 5
)

SELECT 
    fu.DisplayName,
    fu.PostCount,
    fu.TotalUpVotes,
    fu.TotalDownVotes,
    fu.NetVotes,
    ur.Level AS ReputationLevel
FROM 
    FilteredUsers fu
JOIN 
    UserReputation ur ON fu.UserId = ur.UserId
ORDER BY 
    fu.NetVotes DESC,
    fu.PostCount DESC
LIMIT 10;

-- Additionally, let's compute some string expressions for better presentation.
WITH UserAchievements AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    fu.DisplayName,
    fu.PostCount,
    fu.TotalUpVotes,
    fu.TotalDownVotes,
    fu.NetVotes,
    COALESCE(ua.BadgeNames, 'No Badges') AS Achievements,
    ur.Level AS ReputationLevel
FROM 
    FilteredUsers fu
LEFT JOIN 
    UserAchievements ua ON fu.UserId = ua.UserId
JOIN 
    UserReputation ur ON fu.UserId = ur.UserId
ORDER BY 
    fu.NetVotes DESC
LIMIT 10;
