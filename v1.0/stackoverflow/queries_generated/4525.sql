WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) > 100
),
PostTypeComments AS (
    SELECT 
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS CommentTexts
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.PostTypeId
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.Score) AS TotalScore,
    CASE 
        WHEN tu.TotalScore IS NOT NULL THEN 'Top User'
        ELSE 'Regular User'
    END AS UserType,
    pt.CommentCount AS TotalCommentsByPostType,
    pt.CommentTexts
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    TopUsers tu ON u.Id = tu.UserId
LEFT JOIN 
    PostTypeComments pt ON pt.PostTypeId = rp.PostId
WHERE 
    rp.UserRank <= 3
GROUP BY 
    u.DisplayName, tu.TotalScore, pt.CommentCount, pt.CommentTexts
ORDER BY 
    TotalScore DESC, TotalPosts DESC;
