WITH RECURSIVE ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.LastAccessDate DESC) AS rn
    FROM 
        Users u
    WHERE 
        u.LastAccessDate > DATEADD(month, -6, CURRENT_TIMESTAMP)
), 
UserPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), 
RecentPostHistory AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentHistory
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        Posts pt ON ph.PostId = pt.Id
    WHERE 
        ph.CreationDate >= DATEADD(month, -1, CURRENT_TIMESTAMP)
),
FinalResults AS (
    SELECT 
        au.DisplayName,
        au.Reputation,
        up.TotalPosts,
        up.TotalQuestions,
        up.TotalAnswers,
        ub.BadgeCount,
        ub.BadgeNames,
        rph.PostId,
        rph.PostType,
        rph.CreationDate AS RecentHistoryDate
    FROM 
        ActiveUsers au
    LEFT JOIN 
        UserPosts up ON au.Id = up.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON au.Id = ub.UserId
    LEFT JOIN 
        RecentPostHistory rph ON au.Id = rph.UserId
    WHERE 
        au.rn = 1
)
SELECT 
    *,
    CONCAT('User ', DisplayName, 
           ' has ', COALESCE(TotalPosts, 0), 
           ' total posts, ', 
           COALESCE(TotalQuestions, 0), 
           ' questions and ', 
           COALESCE(TotalAnswers, 0), 
           ' answers. They hold ', 
           COALESCE(BadgeCount, 0), 
           ' badge(s): ', 
           COALESCE(BadgeNames, 'None')) AS UserSummary
FROM 
    FinalResults
ORDER BY 
    Reputation DESC, 
    BadgeCount DESC;
