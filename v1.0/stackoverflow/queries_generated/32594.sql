WITH RecursiveTagHierarchy AS (
    SELECT 
        Id AS TagId, 
        TagName, 
        COUNT(*) AS TagCount
    FROM 
        Tags
    GROUP BY 
        Id, TagName
), 
PostStats AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        COALESCE((SELECT COUNT(*) 
                  FROM Comments c 
                  WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, CURRENT_TIMESTAMP)
), 
UserPerformance AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        SUM(COALESCE(ps.Score, 0)) AS TotalScore,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.AnswerCount) AS TotalAnswers,
        COUNT(ps.PostId) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalScore,
        TotalComments,
        TotalAnswers,
        TotalPosts,
        DENSE_RANK() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserPerformance
)
SELECT 
    u.DisplayName, 
    u.Reputation, 
    ua.TotalScore, 
    ua.TotalComments, 
    ua.TotalAnswers, 
    ua.TotalPosts,
    COALESCE(/* Get the last post created by the user */
              (SELECT TOP 1 Title 
               FROM Posts p 
               WHERE p.OwnerUserId = u.Id 
               ORDER BY p.CreationDate DESC), 'No Posts') AS LastPostTitle,
    tg.TagCount
FROM 
    MostActiveUsers ua
LEFT JOIN 
    RecursiveTagHierarchy tg ON ua.UserId = tg.TagId 
WHERE 
    ua.Rank <= 10 /* Only fetch top 10 users */
ORDER BY 
    ua.TotalScore DESC;

