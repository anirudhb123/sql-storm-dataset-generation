WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate,
        p.PostTypeId,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.PostTypeId
), UnansweredQuestions AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.OwnerDisplayName, 
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostTypeId = 1 
        AND (SELECT COUNT(*) FROM Posts WHERE ParentId = rp.PostId) = 0
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes V ON u.Id = V.UserId
    WHERE 
        V.VoteTypeId IN (8, 9) -- Bounty start and Bounty close
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    uq.Title,
    uq.OwnerDisplayName,
    uq.CommentCount,
    tu.TotalBounty,
    CASE 
        WHEN uq.CommentCount > 10 THEN 'Popular'
        WHEN tu.TotalBounty IS NULL THEN 'No Bounty'
        ELSE 'Bounty Hunter'
    END AS UserStatus,
    CASE 
        WHEN (SELECT COUNT(*) FROM Posts p WHERE (p.OwnerUserId = uq.OwnerDisplayName AND p.PostTypeId = 1) AND p.CreationDate < uq.CreationDate) > 0 
        THEN 'Veteran'
        ELSE 'Newbie'
    END AS UserExperience
FROM 
    UnansweredQuestions uq
LEFT JOIN 
    TopUsers tu ON uq.OwnerDisplayName = tu.DisplayName
ORDER BY 
    uq.CommentCount DESC, 
    tu.TotalBounty DESC;

