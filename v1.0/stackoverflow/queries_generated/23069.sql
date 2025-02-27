WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.OwnerUserId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        p.OwnerUserId,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges
    GROUP BY 
        b.UserId
),
AllData AS (
    SELECT
        ru.DisplayName,
        ru.Reputation,
        ru.Rank,
        ra.PostCount,
        ra.QuestionCount,
        ra.LastActivity,
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.UpVotes,
        pd.DownVotes,
        pd.CommentCount,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        RankedUsers ru
    LEFT JOIN RecentActivity ra ON ru.UserId = ra.OwnerUserId
    LEFT JOIN PostDetails pd ON ru.UserId = pd.OwnerUserId
    LEFT JOIN UserBadges ub ON ru.UserId = ub.UserId
)
SELECT 
    *,
    (CASE 
        WHEN Reputation IS NULL THEN 'No Reputation'
        ELSE TO_CHAR(Reputation, '999,999,999') 
     END) AS FormattedReputation,
    (CASE 
        WHEN BadgeCount IS NULL THEN 'No Gold Badges'
        ELSE BadgeCount || ' Gold Badges: ' || BadgeNames
     END) AS BadgeInfo
FROM 
    AllData
ORDER BY 
    Rank, LastActivity DESC
FETCH FIRST 100 ROWS ONLY; 

This SQL query showcases various advanced SQL techniques: 
- Common Table Expressions (CTEs) aggregate user activity, post details, and user badges.
- Window functions rank users based on their reputation.
- Conditional logic formats the output for better readability.
- It uses left joins to ensure that it consolidates data even if some users or posts don’t have corresponding records in linked tables.
- The final result displays a list of users, their reputations, post counts, and badge information with specific formatting applied to certain fields.
