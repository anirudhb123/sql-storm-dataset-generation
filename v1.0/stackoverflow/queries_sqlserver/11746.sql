
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(p.Score, 0)) AS TotalScore,
        AVG(ISNULL(p.AnswerCount, 0)) AS AvgAnswers,
        AVG(ISNULL(p.CommentCount, 0)) AS AvgComments,
        AVG(ISNULL(p.FavoriteCount, 0)) AS AvgFavorites,
        AVG(ISNULL(DATEDIFF(SECOND, p.CreationDate, GETDATE()), 0)) AS AvgPostAgeSeconds
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.PostTypeId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(ISNULL(v.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)
SELECT 
    pst.PostTypeId,
    pst.TotalPosts,
    pst.TotalViews,
    pst.TotalScore,
    pst.AvgAnswers,
    pst.AvgComments,
    pst.AvgFavorites,
    uact.UserId,
    uact.TotalPosts AS UserTotalPosts,
    uact.TotalBounty,
    uact.TotalUpVotes,
    uact.TotalDownVotes
FROM 
    PostStats pst
    LEFT JOIN UserActivity uact ON uact.TotalPosts > 0 
ORDER BY 
    pst.PostTypeId;
