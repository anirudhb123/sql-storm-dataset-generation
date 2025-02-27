WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS NumberOfQuestions,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Join with questions only
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),
RecentBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_DATE - INTERVAL '1 year' -- Only badges awarded in the last year
    GROUP BY 
        b.UserId
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title
),
TopScorers AS (
    SELECT 
        UserId,
        SUM(Score) AS TotalScore
    FROM 
        Votes v
    WHERE 
        v.VoteTypeId IN (2, 3) -- Upvotes and downvotes
    GROUP BY 
        UserId
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    ups.Views,
    ups.NumberOfQuestions,
    ups.TotalScore,
    ups.TotalViews,
    rb.BadgeNames,
    pp.PostRank,
    p.Comments.PostId,
    p.Comments.Title AS QuestionTitle,
    p.Comments.CommentCount
FROM 
    UserPostStats ups
LEFT JOIN 
    RecentBadges rb ON ups.UserId = rb.UserId
LEFT JOIN 
    RankedPosts pp ON ups.UserId = pp.OwnerUserId
LEFT JOIN 
    PostsWithComments p ON pp.Id = p.PostId
WHERE 
    ups.Reputation > 1000 -- Filter for reputable users
ORDER BY 
    ups.TotalScore DESC, ups.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY; -- Pagination for the top 50 users
