WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(ps.UpVoteCount - ps.DownVoteCount) AS NetVoteCount
    FROM 
        Users u
    JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    tu.DisplayName,
    tu.NetVoteCount,
    ps.Title,
    ps.CommentCount,
    COALESCE(tu.NetVoteCount, 0) AS AdjustedVoteCount,
    CASE 
        WHEN ps.rn = 1 THEN 'Top Post'
        ELSE NULL 
    END AS PostRank
FROM 
    PostStats ps
FULL OUTER JOIN 
    TopUsers tu ON ps.PostId = tu.UserId
WHERE 
    ps.Title LIKE '%SQL%'
    OR tu.NetVoteCount IS NOT NULL
ORDER BY 
    AdjustedVoteCount DESC, ps.CommentCount DESC
LIMIT 50;

