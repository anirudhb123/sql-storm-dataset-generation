WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        us.DisplayName,
        us.Reputation,
        us.TotalBounty,
        us.TotalBadges,
        us.TotalPosts,
        us.TotalComments,
        IFNULL(ph.ClosedDate, 'No Closure') AS ClosedStatus,
        RANK() OVER (ORDER BY rp.Score DESC) AS PostRank
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        Posts ph ON rp.PostId = ph.Id
    WHERE 
        rp.RN = 1
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.DisplayName,
    tp.Reputation,
    tp.TotalBounty,
    tp.TotalBadges,
    tp.TotalPosts,
    tp.TotalComments,
    tp.ClosedStatus,
    tp.PostRank
FROM 
    TopPosts tp
WHERE 
    tp.Reputation >= (SELECT AVG(Reputation) FROM Users) 
    AND tp.PostRank <= 10
ORDER BY 
    tp.PostRank;

-- The following outer join demonstrates handling of null logic 
SELECT 
    u.DisplayName AS UserName,
    p.Title,
    COALESCE(SUM(c.Score), 0) AS TotalCommentScore,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    v.VoteTypeId IN (2, 3) -- Considering only Upvotes and Downvotes
GROUP BY 
    u.DisplayName, p.Title
HAVING 
    COUNT(p.Id) > 0
ORDER BY 
    u.DisplayName;

-- Set operator to compare users with and without posts
SELECT 
    u.DisplayName AS PostOwner,
    COUNT(p.Id) AS PostCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(p.Id) = 0
UNION 
SELECT 
    u.DisplayName AS NonPostOwner,
    0 AS PostCount
FROM 
    Users u
WHERE 
    NOT EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = u.Id);
