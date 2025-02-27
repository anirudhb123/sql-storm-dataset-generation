WITH PostStats AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        COALESCE(COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE(COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3), 0) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn,
        p.CreationDate,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
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
        STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
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
        UserBadges ub ON ps.PostID = ua.UserId 
    LEFT JOIN (
        SELECT DISTINCT 
            UserId,
            Reputation 
        FROM 
            Users
        WHERE 
            Location IS NOT NULL AND Location != ''
    ) ua ON 1=1  -- Cartesian product for badge count
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

-- Optional: Testing Outer Joins and Unusual NULL Logic
SELECT 
    p.Id AS PostID,
    p.Title,
    COALESCE(pt.Name, 'Unknown Post Type') AS PostType,
    COALESCE(v.UserId, -1) AS VotingUserId,
    CASE 
        WHEN v.VoteTypeId = 2 THEN 'Vote Up'
        WHEN v.VoteTypeId = 3 THEN 'Vote Down'
        ELSE 'No Vote'
    END AS VoteTypeStatus
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate IS NOT NULL
    AND (v.VoteTypeId IS NULL OR v.UserId IS NULL OR v.CreationDate < NOW() - INTERVAL '100 days')
ORDER BY 
    PostID;
