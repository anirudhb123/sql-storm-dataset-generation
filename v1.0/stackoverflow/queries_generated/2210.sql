WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
UserStats AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.QuestionCount,
        ua.AnswerCount,
        COALESCE(ua.UpVoteCount, 0) - COALESCE(ua.DownVoteCount, 0) AS VoteBalance,
        ua.BadgeCount,
        RANK() OVER (ORDER BY ua.PostCount DESC, VoteBalance DESC) AS Rank
    FROM 
        UserActivity ua
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        VoteBalance,
        BadgeCount,
        Rank
    FROM 
        UserStats
    WHERE 
        Rank <= 10
)
SELECT 
    tu.DisplayName,
    tu.VoteBalance,
    tu.BadgeCount,
    COALESCE(ph.ClosedCount, 0) AS ClosedPostCount,
    COALESCE(ph.EditCount, 0) AS EditPostCount
FROM 
    TopUsers tu
LEFT JOIN (
    SELECT 
        ph.UserId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosedCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN 1 END) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
) ph ON tu.UserId = ph.UserId
ORDER BY 
    tu.Rank;
