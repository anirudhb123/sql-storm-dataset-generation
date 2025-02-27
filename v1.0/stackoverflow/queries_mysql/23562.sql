
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionsCount,
        AnswersCount,
        UpVotesReceived,
        DownVotesReceived,
        @rank := @rank + 1 AS PopularityRank
    FROM 
        UserActivity, (SELECT @rank := 0) r
    WHERE 
        TotalPosts > 0
    ORDER BY 
        TotalPosts DESC
),
BadgeDetails AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserStats AS (
    SELECT 
        au.UserId,
        au.DisplayName,
        au.TotalPosts,
        au.QuestionsCount,
        au.AnswersCount,
        au.UpVotesReceived,
        au.DownVotesReceived,
        COALESCE(bd.TotalBadges, 0) AS TotalBadges,
        COALESCE(bd.BadgeNames, 'None') AS BadgeNames
    FROM 
        ActiveUsers au
    LEFT JOIN 
        BadgeDetails bd ON au.UserId = bd.UserId
),
PostHistories AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS CloseReopenCount,
        COUNT(*) AS DeleteUndeleteCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) OR ph.PostHistoryTypeId IN (12, 13)
    GROUP BY 
        ph.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.QuestionsCount,
    us.AnswersCount,
    us.UpVotesReceived,
    us.DownVotesReceived,
    us.TotalBadges,
    us.BadgeNames,
    COALESCE(ph.CloseReopenCount, 0) AS CloseReopenCount,
    COALESCE(ph.DeleteUndeleteCount, 0) AS DeleteUndeleteCount
FROM 
    UserStats us
LEFT JOIN 
    PostHistories ph ON us.UserId = ph.UserId
WHERE 
    us.QuestionsCount > 5 
    AND us.UpVotesReceived > us.DownVotesReceived
ORDER BY 
    us.TotalPosts DESC, us.DisplayName ASC;
