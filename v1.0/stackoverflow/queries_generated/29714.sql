WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (4,5) THEN 1 ELSE 0 END) AS TagWikis,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostsWithTag,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM 
        Tags t
    JOIN 
        Posts p ON ',' || p.Tags || ',' LIKE '%,' || t.TagName || ',%'
    GROUP BY 
        t.TagName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        PH_TYPE.Name AS HistoryType,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PH_TYPE ON ph.PostHistoryTypeId = PH_TYPE.Id
    GROUP BY 
        ph.PostId, PH_TYPE.Name
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(u.DisplayName, 'Community User') AS Owner,
        p.ViewCount,
        p.Score,
        TH.TagNames,
        phc.ChangeCount AS EditCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            PostId, STRING_AGG(TagName, ', ') AS TagNames 
         FROM 
            Tags t 
         JOIN 
            Posts p ON ',' || p.Tags || ',' LIKE '%,' || t.TagName || ',%'
         GROUP BY 
            PostId) TH ON p.Id = TH.PostId
    LEFT JOIN 
        (SELECT 
            PostId, SUM(ChangeCount) AS ChangeCount 
         FROM 
            PostHistoryStats 
         GROUP BY 
            PostId) phc ON p.Id = phc.PostId
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    us.TagWikis,
    us.TotalUpVotes,
    us.TotalDownVotes,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.ViewCount AS PostViews,
    p.Score AS PostScore,
    p.TagNames AS RelatedTags,
    p.EditCount AS EditHistoryCount
FROM 
    UserStats us
JOIN 
    Users u ON us.UserId = u.Id
JOIN 
    PostActivity p ON p.Owner = u.DisplayName
ORDER BY 
    us.TotalPosts DESC, us.Reputation DESC;
