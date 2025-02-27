WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(rp.CommentCount) AS TotalComments, 
        COUNT(rp.Id) AS TotalPosts
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id
    HAVING 
        SUM(rp.CommentCount) > 10 AND 
        COUNT(rp.Id) > 5
)
SELECT 
    tu.UserId, 
    tu.DisplayName, 
    tu.TotalPosts, 
    tu.TotalComments, 
    rp.Title, 
    rp.CreationDate, 
    rp.Score, 
    rp.UpVotes, 
    rp.DownVotes
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
WHERE 
    rp.UserPostRank <= 5
ORDER BY 
    tu.TotalComments DESC, 
    rp.Score DESC
LIMIT 10;
