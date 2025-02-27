
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
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
        TotalViews,
        TotalScore,
        AcceptedAnswers,
        CommentCount,
        BadgeCount,
        @rownum := @rownum + 1 AS ScoreRank,
        @rownum2 := @rownum2 + 1 AS PostCountRank
    FROM 
        UserActivity, (SELECT @rownum := 0, @rownum2 := 0) r
    ORDER BY 
        TotalScore DESC, PostCount DESC
)

SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalViews,
    TotalScore,
    AcceptedAnswers,
    CommentCount,
    BadgeCount,
    ScoreRank,
    PostCountRank
FROM 
    TopUsers
WHERE 
    ScoreRank <= 10 OR PostCountRank <= 10
ORDER BY 
    ScoreRank, PostCountRank;
