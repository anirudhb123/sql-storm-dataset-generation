WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Tags, 
        p.AcceptedAnswerId, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '>')::int[])
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id
    ORDER BY 
        p.Score DESC, p.ViewCount DESC
), TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(p.Score) AS TotalScore,
        SUM(p.Views) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 50  -- Consider only users with reputation above 50
    GROUP BY 
        u.Id
    HAVING 
        COUNT(p.Id) > 5  -- Users who have authored more than 5 posts
), UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), FinalResults AS (
    SELECT 
        u.DisplayName, 
        r.PostId,
        r.Title, 
        r.TagList, 
        r.CommentCount,
        tb.TotalScore,
        tb.TotalViews,
        ub.BadgeCount
    FROM 
        RankedPosts r
    JOIN 
        TopUsers tb ON r.OwnerUserId = tb.UserId
    JOIN 
        UserBadges ub ON tb.UserId = ub.UserId
    WHERE 
        r.UserPostRank <= 3  -- Select only top 3 posts per user
)
SELECT 
    DisplayName, 
    Title, 
    TagList, 
    CommentCount, 
    TotalScore, 
    TotalViews, 
    BadgeCount
FROM 
    FinalResults
ORDER BY 
    TotalScore DESC, TotalViews DESC;
