WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.CreationDate,
    us.LastAccessDate,
    us.TotalPosts,
    us.TotalComments,
    us.TotalUpVotes,
    us.TotalDownVotes,
    ph.PostHistoryTypeId,
    COUNT(ph.Id) AS TotalPostHistory
FROM 
    UserStats us
LEFT JOIN 
    PostHistory ph ON us.UserId = ph.UserId
GROUP BY 
    us.UserId, ph.PostHistoryTypeId
ORDER BY 
    us.Reputation DESC, us.TotalPosts DESC;
