
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        MAX(p.CreationDate) AS LastPostDate,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsContributed,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id OR t.WikiPostId = p.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.UserDisplayName,
        ph.PostHistoryTypeId,
        p.Title,
        COUNT(ph.Id) AS HistoryCount,
        GROUP_CONCAT(DISTINCT ph.Comment ORDER BY ph.Comment SEPARATOR '; ') AS CommentsMade,
        GROUP_CONCAT(DISTINCT ph.Text ORDER BY ph.Text SEPARATOR '; ') AS TextChanges
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id 
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        ph.PostId, ph.UserId, ph.UserDisplayName, ph.PostHistoryTypeId, p.Title
),
FinalStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.Questions,
        ups.Answers,
        ups.LastPostDate,
        ups.TagsContributed,
        ups.TotalBounties,
        phd.PostId,
        phd.Title,
        phd.HistoryCount,
        phd.CommentsMade,
        phd.TextChanges
    FROM 
        UserPostStats ups
    LEFT JOIN 
        PostHistoryDetails phd ON ups.UserId = phd.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    LastPostDate,
    TagsContributed,
    TotalBounties,
    PostId,
    Title,
    HistoryCount,
    CommentsMade,
    TextChanges
FROM 
    FinalStats
ORDER BY 
    TotalPosts DESC, LastPostDate DESC;
