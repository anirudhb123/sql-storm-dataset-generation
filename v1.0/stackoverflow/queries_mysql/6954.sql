
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        @row_number := IF(@prev_id = p.OwnerUserId, @row_number + 1, 1) AS OwnerRank,
        @prev_id := p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_number := 0, @prev_id := NULL) AS vars
    WHERE 
        p.PostTypeId = 1 
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS QuestionCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    WHERE 
        OwnerRank <= 5
    GROUP BY 
        OwnerDisplayName
),
UserBadges AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    tu.OwnerDisplayName,
    tu.QuestionCount,
    tu.TotalScore,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    TopUsers tu
JOIN 
    UserBadges ub ON tu.OwnerDisplayName = ub.DisplayName
ORDER BY 
    tu.QuestionCount DESC, tu.TotalScore DESC;
