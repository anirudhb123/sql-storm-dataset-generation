WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Id END) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    GROUP BY 
        p.Id
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(ps.UpVotes - ps.DownVotes) AS NetVotes,
        DENSE_RANK() OVER (ORDER BY SUM(ps.UpVotes - ps.DownVotes) DESC) AS Rank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        PostStats ps ON p.Id = ps.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
), 
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.NetVotes,
        ub.BadgeCount,
        ub.LastBadgeDate,
        ROW_NUMBER() OVER (ORDER BY ua.NetVotes DESC, ub.BadgeCount DESC) AS OverallRank
    FROM 
        UserActivity ua
    JOIN 
        UserBadgeCounts ub ON ua.UserId = ub.UserId
    WHERE 
        ub.BadgeCount > 0
)

SELECT 
    tu.UserId,
    u.DisplayName,
    u.Reputation,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.NetVotes,
    tu.BadgeCount,
    tu.LastBadgeDate,
    CASE 
        WHEN tu.OverallRank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributorStatus,
    COALESCE(ps.CloseCount, 0) AS TotalClosures,
    STRING_AGG(DISTINCT p.Title, ', ') AS PostTitles
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.UserId = u.Id
LEFT JOIN 
    PostStats ps ON u.Id = ps.UserId
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
WHERE 
    u.LastAccessDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY 
    tu.UserId, u.DisplayName, u.Reputation, tu.QuestionCount, 
    tu.AnswerCount, tu.NetVotes, tu.BadgeCount, 
    tu.LastBadgeDate, ps.CloseCount, tu.OverallRank
ORDER BY 
    tu.OverallRank;
