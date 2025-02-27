
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(sub_query.CommentCount, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
            PostId,
            COUNT(*) AS CommentCount
         FROM 
            Comments 
         GROUP BY 
            PostId) sub_query ON p.Id = sub_query.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
UserRanked AS (
    SELECT 
        ua.*,
        @userRank := @userRank + 1 AS UserRank
    FROM 
        UserActivity ua,
        (SELECT @userRank := 0) r
    ORDER BY 
        ua.Upvotes DESC, ua.TotalViews DESC, ua.PostCount DESC
),
ClosedPosts AS (
    SELECT 
        p.Id,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        @latestHistory := IF(@currentPostId = p.Id, @latestHistory + 1, 1) AS LatestHistory,
        @currentPostId := p.Id
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        (SELECT @currentPostId := NULL, @latestHistory := 0) r ON TRUE
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    ORDER BY 
        p.Id, ph.CreationDate DESC
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.PostCount,
    ur.Upvotes,
    ur.Downvotes,
    ur.TotalViews,
    ur.TotalComments,
    ur.UserRank,
    COUNT(DISTINCT cp.Id) AS ClosedPostCount,
    AVG(CASE WHEN cp.LatestHistory = 1 THEN 1 ELSE 0 END) AS ReopenedPosts
FROM 
    UserRanked ur
LEFT JOIN 
    ClosedPosts cp ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.Id)
GROUP BY 
    ur.UserId, ur.DisplayName, ur.PostCount, ur.Upvotes, ur.Downvotes, ur.TotalViews, ur.TotalComments, ur.UserRank
HAVING 
    ur.UserRank <= 10 OR (COUNT(DISTINCT cp.Id) > 0 AND ur.TotalViews > 100)
ORDER BY 
    ur.UserRank;
