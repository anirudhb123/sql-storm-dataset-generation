WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        SUM(rp.Score) AS TotalScore
    FROM 
        Users u
    INNER JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT rp.PostId) > 5
),
RecentFeaturedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(ph.Comment, 'No comments') AS LatestComment,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments ph ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalScore,
    rfp.Title AS FeaturedPost,
    rfp.CreationDate AS FeaturedCreationDate,
    rfp.LatestComment
FROM 
    TopUsers tu
LEFT JOIN 
    RecentFeaturedPosts rfp ON rfp.RecentRank <= 3
ORDER BY 
    tu.TotalScore DESC, 
    tu.TotalPosts DESC;
