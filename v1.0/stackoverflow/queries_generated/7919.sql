WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(AVG(v.BountyAmount), 0) AS AverageBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose
    WHERE 
        p.PostTypeId = 1  -- Questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(b.Class = 1, 0)) AS GoldBadges,
        SUM(COALESCE(b.Class = 2, 0)) AS SilverBadges,
        SUM(COALESCE(b.Class = 3, 0)) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1  -- Questions only
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.QuestionCount,
    tu.TotalScore,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.AverageBounty
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.PostId -- Correlating with users based on ownership
WHERE 
    tu.QuestionCount > 5 -- Filter users with more than 5 questions
ORDER BY 
    tu.TotalScore DESC, 
    rp.Score DESC
LIMIT 10;
