WITH RecursiveTopTags AS (
    SELECT t.Id, t.TagName, t.Count,
           ROW_NUMBER() OVER (ORDER BY t.Count DESC) AS TagRank
    FROM Tags t
    WHERE t.Count > 0
),
UserActivity AS (
    SELECT u.Id AS UserId, 
           u.DisplayName,
           COUNT(DISTINCT p.Id) AS TotalPosts,
           SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
           SUM(COALESCE(c.Score, 0)) AS TotalComments,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT p.Id AS PostId, 
           p.Title,
           ph.CreationDate AS HistoryDate,
           ph.Comment,
           ph.UserDisplayName,
           ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM Posts p
    INNER JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.CreationDate >= NOW() - INTERVAL '30 days'
),
TopUsers AS (
    SELECT ua.UserId, 
           ua.DisplayName,
           ua.TotalPosts,
           ua.TotalViews,
           ua.TotalComments,
           ua.TotalQuestions,
           ua.TotalAnswers,
           RANK() OVER (ORDER BY ua.TotalViews DESC) AS ViewRank
    FROM UserActivity ua
    WHERE ua.TotalPosts > 0
)
SELECT t.TagName,
       tt.TotalQuestions,
       tt.TotalAnswers,
       uu.DisplayName AS UserDisplayName,
       uu.TotalViews,
       uu.TotalComments,
       rh.HistoryDate,
       rh.Comment,
       rh.UserDisplayName AS HistoryUser
FROM RecursiveTopTags tt
LEFT JOIN (
    SELECT TagId, 
           COUNT(DISTINCT p.Id) AS TotalQuestions, 
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM Tags t
    LEFT JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE t.Count IN (SELECT Id FROM RecursiveTopTags WHERE TagRank <= 10)
    GROUP BY TagId
) tt ON tt.TagId = t.Id
LEFT JOIN TopUsers uu ON uu.UserId IN (SELECT DISTINCT p.OwnerUserId 
                                        FROM Posts p 
                                        WHERE p.Tags LIKE '%' || t.TagName || '%')
LEFT JOIN RecentPostHistory rh ON rh.PostId = tt.PostId
WHERE tt.ViewRank <= 5 AND rh.HistoryRank = 1
ORDER BY tt.TotalQuestions DESC, uu.TotalViews DESC;
