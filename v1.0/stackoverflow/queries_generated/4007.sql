WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(vs.Score, 0)) AS TotalScore,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        (SELECT 
            PostId, SUM(Score) AS Score 
         FROM 
            Comments 
         GROUP BY 
            PostId
        ) AS vs ON p.Id = vs.PostId
    WHERE 
        u.Reputation > 500
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        TotalScore, 
        BadgeCount,
        LastPostDate,
        RANK() OVER (ORDER BY TotalScore DESC, PostCount DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.BadgeCount,
    tu.LastPostDate,
    ph.Comment AS LastEditComment,
    COALESCE(CAST(NULLIF(p.AcceptedAnswerId, -1) AS INTEGER), p.ParentId) AS FinalPostLink
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    tu.Rank <= 10 
    AND ph.CreationDate = (SELECT MAX(ph2.CreationDate) FROM PostHistory ph2 WHERE ph2.PostId = p.Id)
ORDER BY 
    tu.TotalScore DESC;

-- Additionally, include details of posts linked to each user that are either closed or have zero votes
SELECT 
    lu.UserId,
    lu.DisplayName,
    pll.RelatedPostId,
    p.Title,
    CASE WHEN p.ClosedDate IS NOT NULL THEN 'Closed' ELSE 'Open' END AS PostStatus,
    COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
    COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
FROM 
    Users lu
LEFT JOIN 
    PostLinks pll ON lu.Id = pll.PostId
LEFT JOIN 
    Posts p ON pll.RelatedPostId = p.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    (p.ClosedDate IS NOT NULL OR v.Id IS NULL)
GROUP BY 
    lu.UserId, lu.DisplayName, pll.RelatedPostId, p.Title, p.ClosedDate
ORDER BY 
    lu.DisplayName;
