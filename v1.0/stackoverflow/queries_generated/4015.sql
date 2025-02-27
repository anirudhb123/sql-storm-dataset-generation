WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT r.Id) AS TotalPosts,
        SUM(r.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    WHERE 
        r.PostRank <= 5
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalScore,
    COALESCE(SUM(b.Class), 0) AS BadgeCount,
    ARRAY_AGG(DISTINCT pt.Name) AS PostTypeNames
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId 
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    tu.DisplayName, tu.TotalPosts, tu.TotalScore
HAVING 
    COALESCE(SUM(b.Class), 0) > 1
ORDER BY 
    tu.TotalScore DESC, tu.TotalPosts DESC;
