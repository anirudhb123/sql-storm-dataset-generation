WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalPosts DESC, UpVotes DESC) AS UserRank
    FROM 
        UserPostStats
),
RecentPostHistory AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)

SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalPosts,
    COALESCE(rph.Comment, 'No recent changes') AS RecentChangeComment,
    COALESCE(rph.CreationDate, 'No recent changes') AS RecentChangeDate
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPostHistory rph ON tu.UserId = rph.UserId AND rph.rn = 1
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.UserRank;
