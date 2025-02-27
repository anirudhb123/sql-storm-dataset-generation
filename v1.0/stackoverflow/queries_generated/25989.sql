WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        OwnerName, 
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews,
        AVG(CommentCount) AS AvgComments,
        RANK() OVER (ORDER BY SUM(Score) DESC) AS ScoreRank
    FROM 
        RankedPosts
    WHERE 
        UserRank = 1 -- Only take the latest post by each user
    GROUP BY 
        OwnerName
    HAVING 
        SUM(Score) > 0
)
SELECT 
    u.DisplayName,
    u.Reputation,
    t.TotalScore,
    t.TotalViews,
    t.AvgComments,
    RANK() OVER (ORDER BY t.TotalScore DESC) AS OverallRank
FROM 
    TopUsers t
JOIN 
    Users u ON u.DisplayName = t.OwnerName
WHERE 
    t.ScoreRank <= 10 -- Top 10 users by score
ORDER BY 
    OverallRank;
