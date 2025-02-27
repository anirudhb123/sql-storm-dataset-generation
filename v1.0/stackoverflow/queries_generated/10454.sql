WITH UserMetrics AS (
    SELECT 
        Id AS UserId,
        Reputation,
        Views,
        UpVotes,
        DownVotes,
        EmailHash
    FROM 
        Users
),
PostMetrics AS (
    SELECT 
        Id AS PostId,
        PostTypeId,
        Score,
        ViewCount,
        CreationDate,
        AnswerCount,
        CommentCount,
        FavoriteCount,
        OwnerUserId
    FROM 
        Posts
),
JoinMetrics AS (
    SELECT 
        u.UserId,
        p.PostId,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes
    FROM 
        UserMetrics u
    JOIN 
        PostMetrics p ON u.UserId = p.OwnerUserId
)
SELECT 
    PostTypeId,
    COUNT(PostId) AS TotalPosts,
    AVG(Score) AS AvgScore,
    SUM(ViewCount) AS TotalViews,
    AVG(AnswerCount) AS AvgAnswerCount,
    AVG(CommentCount) AS AvgCommentCount,
    AVG(FavoriteCount) AS AvgFavoriteCount,
    AVG(Reputation) AS AvgUserReputation,
    SUM(UpVotes) AS TotalUpVotes,
    SUM(DownVotes) AS TotalDownVotes
FROM 
    JoinMetrics
GROUP BY 
    PostTypeId
ORDER BY 
    TotalPosts DESC;
