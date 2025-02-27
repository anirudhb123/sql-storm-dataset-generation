WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.ViewCount,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.ViewCount,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.Id
    WHERE 
        p.PostTypeId = 2 -- Answers
),
UserAggregate AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
    GROUP BY 
        u.Id, u.DisplayName
),
PostRanking AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        Rank() OVER (ORDER BY p.ViewCount DESC) AS ViewRank,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate ASC) AS UserPostRank
    FROM 
        Posts p
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.TotalBadges,
    u.TotalBounties,
    pp.Title AS TopPostTitle,
    pp.ViewCount AS TopPostViewCount,
    pp.ViewRank,
    pp.UserPostRank,
    r.Level AS AnswerLevel
FROM 
    UserAggregate u
LEFT JOIN 
    PostRanking pp ON u.UserId = pp.OwnerUserId AND pp.ViewRank = 1 -- Top viewed post per user
LEFT JOIN 
    RecursivePostCTE r ON r.OwnerUserId = u.UserId
WHERE 
    u.PostCount > 0
ORDER BY 
    u.TotalBadges DESC, u.PostCount DESC, pp.ViewCount DESC
LIMIT 100;
