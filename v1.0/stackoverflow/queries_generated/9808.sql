WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        AVG(v.BountyAmount) OVER (PARTITION BY p.Id) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 /* Questions only */
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        UPPER(u.Location) AS UppercaseLocation, 
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.Views
),
FinalOutput AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.Views,
        us.BadgeCount,
        COUNT(rp.PostId) AS QuestionCount,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AverageViewCount,
        SUM(rp.CommentCount) AS TotalComments,
        AVG(rp.AverageBounty) AS AverageBountyPerQuestion
    FROM 
        UserStats us
    LEFT JOIN 
        RankedPosts rp ON us.UserId = rp.PostId 
    GROUP BY 
        us.UserId, us.DisplayName, us.Reputation, us.Views, us.BadgeCount
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    Views, 
    BadgeCount, 
    QuestionCount, 
    TotalScore, 
    AverageViewCount, 
    TotalComments, 
    AverageBountyPerQuestion 
FROM 
    FinalOutput 
WHERE 
    Reputation > 1000 
ORDER BY 
    TotalScore DESC, 
    QuestionCount DESC, 
    AverageViewCount DESC;
