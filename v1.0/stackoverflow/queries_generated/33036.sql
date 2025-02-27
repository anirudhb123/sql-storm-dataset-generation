WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
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
        p.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) > 0
),
PostWithCommentsAndVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        p.CreationDate,
        p.Score,
        pt.Name AS PostType
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
),
RecursiveParentPosts AS (
    SELECT 
        Id,
        Title,
        ParentId
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId
    FROM 
        Posts p
    INNER JOIN 
        RecursiveParentPosts rpp ON p.ParentId = rpp.Id
),
CombinedData AS (
    SELECT 
        r.UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AvgScore,
        STRING_AGG(DISTINCT p.Tags, ', ') AS Tags
    FROM 
        RankedPosts r
    JOIN 
        Users u ON r.OwnerUserId = u.Id
    JOIN 
        Posts p ON r.Id = p.Id
    GROUP BY 
        r.UserId, u.DisplayName
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalScore,
    tu.PostCount,
    p.Title,
    p.CommentCount,
    p.VoteCount,
    p.CreationDate,
    p.PostType,
    CASE 
        WHEN p.Score IS NULL THEN 'No Score'
        WHEN p.Score < 0 THEN 'Negative Score'
        ELSE 'Positive Score'
    END AS ScoreStatus
FROM 
    TopUsers tu
JOIN 
    PostWithCommentsAndVotes p ON tu.UserId = p.OwnerUserId
ORDER BY 
    tu.TotalScore DESC, 
    tu.PostCount DESC
OPTION (MAXRECURSION 100);
