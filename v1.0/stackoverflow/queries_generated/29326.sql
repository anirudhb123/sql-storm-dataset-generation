WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserRankByViews
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
AggregateDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViewCount,
        AVG(p.AnswerCount) AS AvgAnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostsTags pt ON p.Id = pt.PostId
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    WHERE 
        u.Reputation > 1000 -- Only users with reputation above a certain threshold
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalViewCount,
        AvgAnswerCount,
        BadgeCount,
        RANK() OVER (ORDER BY TotalViewCount DESC) AS RankByViews
    FROM 
        AggregateDetails
)
SELECT 
    tu.RankByViews,
    tu.DisplayName,
    tu.TotalViewCount,
    tu.AvgAnswerCount,
    tu.BadgeCount,
    rp.Title AS TopPostTitle,
    rp.ViewCount AS TopPostViewCount
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.UserRankByViews = 1
WHERE 
    tu.RankByViews <= 10 -- Get top 10 users
ORDER BY 
    tu.RankByViews;
