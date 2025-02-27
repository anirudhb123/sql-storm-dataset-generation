WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
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
        SUM(rp.Score) AS TotalScore,
        COUNT(rp.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE 
        rp.UserPostRank <= 5
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(rp.Id) >= 3
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalScore,
    tu.PostCount,
    COALESCE(SUBSTRING_AGG(DISTINCT p.Tags, ', '), 'No Tags') AS PostTags,
    COUNT(DISTINCT bh.Id) AS BadgeCount,
    MAX(CASE WHEN bp.Id IS NOT NULL THEN 'Has Backlink' ELSE 'No Backlink' END) AS BacklinkStatus
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON p.OwnerUserId = tu.UserId
LEFT JOIN 
    Badges bh ON bh.UserId = tu.UserId
LEFT JOIN 
    PostLinks pl ON pl.PostId = p.Id
LEFT JOIN 
    Posts bp ON bp.Id = pl.RelatedPostId AND pl.LinkTypeId = 3
GROUP BY 
    tu.UserId, tu.DisplayName, tu.TotalScore, tu.PostCount
ORDER BY 
    tu.TotalScore DESC, tu.PostCount DESC
LIMIT 10;
