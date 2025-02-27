WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- only questions
        AND p.ViewCount > 100  -- filter questions with substantial views
), TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(bp.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes vp ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
), TopContent AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        tu.DisplayName AS Author,
        tu.QuestionCount,
        tu.TotalBounties,
        tu.GoldBadges,
        tu.SilverBadges,
        tu.BronzeBadges
    FROM 
        RankedPosts rp
    JOIN 
        TopUsers tu ON rp.OwnerUserId = tu.UserId
    WHERE 
        rp.Rank <= 3  -- top 3 highest scoring posts per user
)
SELECT 
    tc.PostId,
    tc.Title,
    tc.Body,
    tc.ViewCount,
    tc.Score,
    tc.CreationDate,
    tc.Author,
    tc.QuestionCount,
    tc.TotalBounties,
    tc.GoldBadges,
    tc.SilverBadges,
    tc.BronzeBadges
FROM 
    TopContent tc
ORDER BY 
    tc.Score DESC, 
    tc.ViewCount DESC;
