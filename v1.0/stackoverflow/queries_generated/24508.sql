WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN (
            SELECT 
                PostId, 
                SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
                SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
            FROM Votes
            GROUP BY PostId
        ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id
), RecentPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '90 days'
), DetailedPostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(ph.PostHistoryTypeId, 0) AS LastActionType,
        COALESCE(ph.Comment, '') AS LastChangeComment
    FROM 
        Posts p
        LEFT JOIN PostHistory ph ON p.Id = ph.PostId
        WHERE 
        ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = p.Id)
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.TotalComments,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.ViewCount AS RecentPostViews,
    dpi.LastActionType,
    dpi.LastChangeComment
FROM 
    UserPostStats ups
    LEFT JOIN RecentPosts rp ON ups.UserId = rp.OwnerUserId AND rp.rn = 1
    LEFT JOIN DetailedPostInfo dpi ON rp.PostId = dpi.PostId
WHERE 
    ups.TotalPosts > 0 OR
    (SELECT COUNT(*) FROM Posts WHERE CreationDate >= NOW() - INTERVAL '1 year') = 0
ORDER BY 
    ups.TotalPosts DESC,
    ups.UserId
LIMIT 100;
