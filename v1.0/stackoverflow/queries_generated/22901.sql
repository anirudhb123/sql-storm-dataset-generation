WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotesCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotesCount,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersCount,
        COUNT(distinct b.Id) AS TotalBadges,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(v.VoteTypeId = 2), 0) - COALESCE(SUM(v.VoteTypeId = 3), 0) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT UserId, DisplayName, UpVotesCount, DownVotesCount, TotalPosts, QuestionsCount, AnswersCount, TotalBadges,
           RANK() OVER (ORDER BY UpVotesCount DESC, DownVotesCount ASC) AS UpvotesRank
    FROM UserStatistics
    WHERE TotalPosts > 0
),
UserBadges AS (
    SELECT 
        UserId, 
        STRING_AGG(Name || ' (' || Date::date || ')', ', ') AS BadgeList
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostHistorySummary AS (
    SELECT 
        ph.UserId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS TotalCloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS TotalReopenVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) - COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS NetCloseActivity
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
)
SELECT 
    u.DisplayName,
    u.UpVotesCount,
    u.DownVotesCount,
    u.TotalPosts,
    u.QuestionsCount,
    u.AnswersCount,
    u.TotalBadges,
    b.BadgeList,
    phs.TotalCloseVotes,
    phs.TotalReopenVotes,
    phs.NetCloseActivity,
    CASE 
        WHEN phs.NetCloseActivity < 0 THEN 'More closed posts than reopened'
        WHEN phs.NetCloseActivity = 0 THEN 'Balanced closure and reopening activity'
        ELSE 'More reopened posts than closed'
    END AS ClosureSummary
FROM 
    TopUsers u
LEFT JOIN 
    UserBadges b ON u.UserId = b.UserId
LEFT JOIN 
    PostHistorySummary phs ON u.UserId = phs.UserId
WHERE 
    u.Rank <= 10
ORDER BY 
    u.UpVotesCount DESC;
