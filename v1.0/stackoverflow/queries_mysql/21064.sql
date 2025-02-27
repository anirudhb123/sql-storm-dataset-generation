
WITH PostStats AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 END), 0) AS DownvoteCount,
        p.CreationDate,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (CURDATE() - INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.Reputation
),
AcceptedAnswers AS (
    SELECT 
        p.Id AS QuestionID,
        COUNT(a.Id) AS AcceptedAnswersCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(DISTINCT b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
CombinedStats AS (
    SELECT 
        ps.PostID,
        ps.Title,
        ps.UpvoteCount - ps.DownvoteCount AS NetVotes,
        aa.AcceptedAnswersCount,
        ub.BadgeCount,
        ub.BadgeNames,
        ps.OwnerReputation
    FROM 
        PostStats ps
    LEFT JOIN 
        AcceptedAnswers aa ON ps.PostID = aa.QuestionID
    LEFT JOIN 
        UserBadges ub ON ps.PostID = ub.UserId 
    LEFT JOIN (
        SELECT DISTINCT 
            UserId,
            Reputation 
        FROM 
            Users
        WHERE 
            Location IS NOT NULL AND Location != ''
    ) ua ON 1=1  
)
SELECT 
    PostID,
    Title,
    NetVotes,
    AcceptedAnswersCount,
    COALESCE(BadgeCount, 0) AS UserBadgeCount,
    CONCAT('User has badges: ', COALESCE(BadgeNames, 'None')) AS BadgeDetails,
    CASE 
        WHEN OwnerReputation IS NULL THEN 'Reputation data unavailable'
        WHEN OwnerReputation > 1000 THEN 'Highly trusted user'
        ELSE 'User with limited reputation'
    END AS ReputationStatus
FROM 
    CombinedStats
WHERE 
    (NetVotes > 0 OR AcceptedAnswersCount > 0)
ORDER BY 
    NetVotes DESC, Title
LIMIT 50;
