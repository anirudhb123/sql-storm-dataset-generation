WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS UpVotesReceived,
        SUM(v.VoteTypeId = 3) AS DownVotesReceived,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Filter for closed, reopened, or deleted
),
PostMetrics AS (
    SELECT 
        p.UserId,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPosts,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedPosts,
        SUM(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS DeletedPosts
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalComments,
    us.UpVotesReceived,
    us.DownVotesReceived,
    pm.ClosedPosts,
    pm.ReopenedPosts,
    pm.DeletedPosts,
    COUNT(DISTINCT pa.PostId) AS RelatedPostCount,
    SUM(pa.ViewCount) AS TotalViews,
    AVG(pa.AnswerCount) AS AverageAnswersPerPost
FROM 
    UserStats us
LEFT JOIN 
    PostMetrics pm ON us.UserId = pm.UserId
LEFT JOIN 
    PostActivity pa ON us.UserId = pa.UserId
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, pm.ClosedPosts, pm.ReopenedPosts, pm.DeletedPosts
ORDER BY 
    us.Reputation DESC, us.TotalPosts DESC;
