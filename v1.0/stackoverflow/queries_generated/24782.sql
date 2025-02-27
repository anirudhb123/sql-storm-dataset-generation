WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Filtering for Questions
),
UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass,
        SUM(CASE WHEN b.TagBased = 1 THEN 1 ELSE 0 END) AS TagBasedBadges,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedQuestions
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY u.Id
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(DISTINCT v.UserId) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        coalesce(rv.TotalVotes, 0) AS TotalVotes,
        coalesce(rv.UpVotes, 0) AS UpVotes,
        coalesce(rv.DownVotes, 0) AS DownVotes,
        u.Username,
        b.BadgeCount,
        b.HighestBadgeClass,
        b.TagBasedBadges,
        b.QuestionCount,
        b.ClosedQuestions
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN RecentVotes rv ON p.Id = rv.PostId
    LEFT JOIN UserBadgeStats b ON u.Id = b.UserId
    WHERE p.Id IN (SELECT PostId FROM RecursivePostCTE WHERE RowNum <= 5)  -- Get only last 5 questions per user
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.TotalVotes,
    pd.UpVotes,
    pd.DownVotes,
    pd.Username,
    pd.BadgeCount,
    pd.HighestBadgeClass,
    CASE 
        WHEN pd.ClosedQuestions > 0 THEN 'Closed Questions: ' || pd.ClosedQuestions 
        ELSE 'No Closed Questions'
    END AS ClosedQuestionsInfo,
    CASE 
        WHEN pd.TagBasedBadges > 0 THEN 'Tag Based Badges: ' || pd.TagBasedBadges 
        ELSE 'No Tag Based Badges'
    END AS TagBasedBadgesInfo
FROM PostDetails pd
ORDER BY pd.CreationDate DESC 
LIMIT 50;

-- The above query provides insights into the recent questions posted by users,
-- along with their voting activity and badge stats, showcasing the interplay of 
-- various SQL constructs such as recursive CTEs, outer joins, window functions, 
-- and conditional logic to pull a comprehensive report.
