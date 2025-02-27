WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM 
        UserPostStats
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalStats AS (
    SELECT 
        t.UserId,
        t.DisplayName,
        t.PostCount,
        t.QuestionCount,
        t.AnswerCount,
        COALESCE(b.BadgeNames, 'No Badges') AS BadgeNames,
        COALESCE(b.TotalBadges, 0) AS TotalBadges
    FROM 
        TopUsers t
    LEFT JOIN 
        UserBadges b ON t.UserId = b.UserId
)
SELECT 
    fs.UserId,
    fs.DisplayName,
    fs.PostCount,
    fs.QuestionCount,
    fs.AnswerCount,
    fs.BadgeNames,
    fs.TotalBadges,
    CASE 
        WHEN fs.TotalBadges > 5 THEN 'Gold Member'
        WHEN fs.TotalBadges BETWEEN 2 AND 5 THEN 'Silver Member'
        ELSE 'Bronze Member'
    END AS MembershipStatus,
    (SELECT 
        AVG(v.BountyAmount) 
     FROM 
        Votes v 
     WHERE 
        v.UserId = fs.UserId AND v.BountyAmount IS NOT NULL) AS AvgBounty
FROM 
    FinalStats fs
WHERE 
    fs.PostCount > 10
ORDER BY 
    fs.TotalBadges DESC, 
    fs.TotalScore DESC
LIMIT 50;
