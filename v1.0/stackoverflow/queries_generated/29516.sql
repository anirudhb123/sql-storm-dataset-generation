WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.Id) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
    WHERE 
        p.PostTypeId = 1  -- Only considering questions
    GROUP BY 
        p.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS TotalQuestions,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id
),
TopBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId, b.Name
),
RankedBadges AS (
    SELECT 
        UserId, 
        BadgeName, 
        BadgeCount,
        RANK() OVER (PARTITION BY UserId ORDER BY BadgeCount DESC) AS BadgeRank
    FROM 
        TopBadges
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalViews,
        ups.TotalScore,
        rb.BadgeName,
        rb.BadgeCount
    FROM 
        Users u
    JOIN 
        UserPostStats ups ON u.Id = ups.UserId
    LEFT JOIN 
        RankedBadges rb ON u.Id = rb.UserId AND rb.BadgeRank = 1 -- Top badge for the user
)
SELECT 
    ud.DisplayName,
    ud.Reputation,
    ud.TotalPosts,
    ud.TotalQuestions,
    ud.TotalAnswers,
    ud.TotalViews,
    ud.TotalScore,
    ud.BadgeName,
    ud.BadgeCount,
    pct.TagCount
FROM 
    UserDetails ud
JOIN 
    PostTagCounts pct ON ud.TotalQuestions > 0  -- Only users with questions
ORDER BY 
    ud.Reputation DESC, 
    pct.TagCount DESC;
