WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        RANK() OVER (ORDER BY SUM(v.VoteTypeId = 2) DESC) AS VoteRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, Reputation, TotalPosts, TotalQuestions, TotalAnswers, TotalUpVotes, TotalDownVotes
    FROM 
        UserStats
    WHERE 
        TotalPosts > 0
    ORDER BY 
        Reputation DESC
    LIMIT 5
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(cl.CloseReason, 'Not Closed') AS CloseReason
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            ph.PostId, 
            STRING_AGG(cr.Name, ', ') AS CloseReason 
         FROM PostHistory ph 
         JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
         WHERE ph.PostHistoryTypeId IN (10, 11) 
         GROUP BY ph.PostId) cl ON p.Id = cl.PostId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    pd.Title,
    pd.CreationDate,
    pd.LastActivityDate,
    pd.CommentCount,
    pd.CloseReason
FROM 
    TopUsers tu
JOIN 
    PostDetails pd ON tu.UserId = pd.OwnerDisplayName
ORDER BY 
    tu.Reputation DESC, pd.LastActivityDate DESC;
