
WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
RecentPostHistories AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        p.Title,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS LatestHistory
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.TotalScore,
    ups.QuestionCount,
    ups.AnswerCount,
    COALESCE(RH.RecentActivity, 'No recent activity') AS RecentActivity
FROM UserPostStats ups
LEFT JOIN (
    SELECT 
        UserId,
        LISTAGG(CONCAT('Post ID: ', PostId, ' - Title: ', Title, ' (', Comment, ')'), '; ') WITHIN GROUP (ORDER BY PostId) AS RecentActivity
    FROM RecentPostHistories
    WHERE LatestHistory = 1
    GROUP BY UserId
) RH ON ups.UserId = RH.UserId
WHERE ups.Rank <= 10
ORDER BY ups.TotalScore DESC, ups.DisplayName ASC;
