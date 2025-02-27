
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        CommentCount,
        VoteCount,
        TotalScore,
        BadgeCount,
        @row_num := @row_num + 1 AS Rank
    FROM 
        UserPostStats, (SELECT @row_num := 0) r
    ORDER BY 
        TotalScore DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    CommentCount,
    VoteCount,
    TotalScore,
    BadgeCount
FROM 
    TopUsers
WHERE 
    Rank <= 10;
