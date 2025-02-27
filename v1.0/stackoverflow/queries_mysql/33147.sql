
WITH RECURSIVE RecursiveUserPosts AS (
    SELECT 
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        @row_number := IF(@prev_user = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @prev_user := p.OwnerUserId
    FROM 
        Posts p,
        (SELECT @row_number := 0, @prev_user := NULL) AS init
    WHERE 
        p.PostTypeId = 1
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL 30 DAY 
    GROUP BY 
        v.PostId
),
TopQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.Score AS QuestionScore,
        COALESCE(rv.UpVotes, 0) AS RecentUpVotes,
        COALESCE(rv.DownVotes, 0) AS RecentDownVotes,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ub.BadgeCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        RecentVotes rv ON p.Id = rv.PostId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        p.PostTypeId = 1  
        AND (p.Score >= 10 OR ub.BadgeCount >= 3) 
),
TopActiveUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore
    FROM 
        Posts
    WHERE 
        PostTypeId IN (1, 2)  
    GROUP BY 
        OwnerUserId
    HAVING
        COUNT(*) > 5  
)
SELECT 
    tq.QuestionId,
    tq.Title,
    tq.QuestionScore,
    tq.RecentUpVotes,
    tq.RecentDownVotes,
    tq.OwnerDisplayName,
    tq.BadgeCount,
    tu.PostCount,
    tu.TotalScore,
    @ranking := @ranking + 1 AS Ranking
FROM 
    TopQuestions tq,
    (SELECT @ranking := 0) AS init
JOIN 
    TopActiveUsers tu ON tq.OwnerUserId = tu.OwnerUserId
ORDER BY 
    tq.QuestionScore DESC, tq.RecentUpVotes DESC;
