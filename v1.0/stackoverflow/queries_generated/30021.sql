WITH RecursivePostLinks AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        1 AS Depth
    FROM 
        PostLinks pl
    UNION ALL
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        Depth + 1
    FROM 
        PostLinks pl
    JOIN 
        RecursivePostLinks rpl ON pl.RelatedPostId = rpl.PostId
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopPerformers AS (
    SELECT
        ue.UserId,
        ue.DisplayName,
        ue.UpVotesCount,
        ue.DownVotesCount,
        ue.CommentsCount,
        ue.PostsCount,
        ue.TotalScore,
        RANK() OVER (ORDER BY ue.TotalScore DESC) AS PerformanceRank
    FROM 
        UserEngagement ue
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.UpVotesCount,
    t.DownVotesCount,
    t.CommentsCount,
    t.PostsCount,
    t.TotalScore,
    COALESCE((SELECT COUNT(*) FROM Posts p WHERE p.AcceptedAnswerId IN (SELECT pl.RelatedPostId FROM RecursivePostLinks rpl WHERE rpl.PostId = p.Id)), 0) AS AcceptedAnswersCount
FROM
    TopPerformers t
WHERE 
    t.PerformanceRank <= 10
ORDER BY 
    t.TotalScore DESC;
