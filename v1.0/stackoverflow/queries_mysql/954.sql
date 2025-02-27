
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @row_num := IF(@prev_user_id = p.OwnerUserId, @row_num + 1, 1) AS PostRank,
        @prev_user_id := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @row_num := 0, @prev_user_id := NULL) AS init
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY COUNT(rp.PostId) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        RecentPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(rp.PostId) > 5
)
SELECT  
    u.UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(SUM(rp.UpVotes) - SUM(rp.DownVotes), 0) AS NetVotes,
    COALESCE(SUM(rp.CommentCount), 0) AS TotalComments,
    CASE 
        WHEN u.Reputation > 1000 THEN 'Veteran'
        ELSE 'Novice'
    END AS UserCategory
FROM 
    TopUsers u
LEFT JOIN 
    RecentPosts rp ON u.UserId = rp.OwnerUserId
GROUP BY 
    u.UserId, u.DisplayName, u.Reputation
HAVING 
    COUNT(rp.PostId) > 0
ORDER BY 
    NetVotes DESC, TotalComments DESC;
