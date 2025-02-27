WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
        AND p.PostTypeId IN (1, 2) -- Only Questions and Answers
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
    LIMIT 10
),
PostLinksCount AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS LinksCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.AnswerCount,
    u.DisplayName AS OwnerName,
    tu.TotalScore,
    tu.PostCount,
    COALESCE(plc.LinksCount, 0) AS LinkReferences
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
JOIN 
    TopUsers tu ON u.Id = tu.UserId
LEFT JOIN 
    PostLinksCount plc ON r.PostId = plc.PostId
WHERE 
    r.UserRank <= 5 -- Top 5 ranked posts for each user
ORDER BY 
    r.Score DESC, r.CreationDate DESC;
