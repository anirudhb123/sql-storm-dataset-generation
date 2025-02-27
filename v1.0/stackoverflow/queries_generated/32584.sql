WITH RankedPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        Tags,
        Score,
        OwnerUserId,
        AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY Score DESC) AS Rank
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1 -- Questions only
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        LastAccessDate,
        Views,
        (UpVotes - DownVotes) AS VoteBalance
    FROM 
        Users
    WHERE 
        Reputation > 1000
),
PostCloseReasons AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        ph.CreationDate AS CloseDate,
        cr.Name AS CloseReason,
        ph.UserDisplayName AS ClosedBy
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),
UserPostsStats AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        COALESCE(up.BadgeCount, 0) AS BadgeCount,
        COALESCE(up.BadgeNames, 'No Badges') AS BadgeNames,
        COUNT(rp.Id) AS PostCount,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.Score) AS AvgScore
    FROM 
        UserReputation ur
    LEFT JOIN 
        UserBadges up ON ur.UserId = up.UserId
    LEFT JOIN 
        RankedPosts rp ON ur.UserId = rp.OwnerUserId
    GROUP BY 
        ur.UserId, ur.Reputation
)
SELECT 
    us.UserId,
    us.Reputation,
    us.BadgeCount,
    us.BadgeNames,
    us.PostCount,
    us.TotalScore,
    us.AvgScore,
    pcr.CloseReason,
    pcr.CloseDate,
    pcr.ClosedBy
FROM 
    UserPostsStats us
LEFT JOIN 
    PostCloseReasons pcr ON us.UserId = pcr.PostId
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.TotalScore DESC, 
    us.Reputation DESC
LIMIT 10;
