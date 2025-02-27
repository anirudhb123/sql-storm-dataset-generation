WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.Views,
        COALESCE(COUNT(a.Id), 0) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id
    ORDER BY 
        NetVotes DESC
    LIMIT 10
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS SuggestedEditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.Views,
    rp.AnswerCount,
    tu.DisplayName AS TopUser,
    tu.NetVotes,
    phs.CloseReopenCount,
    phs.DeleteUndeleteCount,
    phs.SuggestedEditCount
FROM 
    RecentPosts rp
JOIN 
    PostHistoryStats phs ON phs.PostId = rp.PostId
JOIN 
    TopUsers tu ON tu.UserId = (SELECT u.Id FROM Users u ORDER BY u.Reputation DESC LIMIT 1)
ORDER BY 
    rp.Score DESC, rp.Views DESC;
