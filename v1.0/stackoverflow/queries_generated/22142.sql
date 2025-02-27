WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(COALESCE(v.VoteTypeId, 0)) AS TotalVotes,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.LastActivityDate,
        pt.Name AS PostType,
        COALESCE(CLOSED.ClosedCount, 0) AS ClosedPostCount,
        COALESCE(HIST.EditCount, 0) AS EditCount,
        CASE 
            WHEN p.ViewCount > 1000 THEN 'Hot' 
            WHEN p.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate'
            ELSE 'Cold' 
        END AS Popularity
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS ClosedCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId = 10 -- Post Closed
        GROUP BY 
            PostId
    ) CLOSED ON p.Id = CLOSED.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS EditCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
        GROUP BY 
            PostId
    ) HIST ON p.Id = HIST.PostId
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount IS NULL THEN 0 ELSE p.ViewCount END) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
),
FilteredPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        ua.DisplayName AS Owner,
        pd.Popularity,
        ts.TagName,
        ROW_NUMBER() OVER (PARTITION BY pd.Popularity ORDER BY pd.LastActivityDate DESC) AS PopularityRank
    FROM 
        PostDetails pd
    JOIN 
        Users ua ON pd.PostId IN (SELECT ParentId FROM Posts WHERE AcceptedAnswerId IS NOT NULL)
    LEFT JOIN 
        TagStatistics ts ON ts.PostCount > 5
    WHERE 
        pd.ClosedPostCount = 0
)
SELECT 
    fp.Title,
    fp.Owner,
    fp.Popularity,
    STRING_AGG(fp.TagName, ', ') AS Tags,
    'User has rank: ' || TO_CHAR(ua.UserRank) AS UserRankInfo
FROM 
    FilteredPosts fp
JOIN 
    UserActivity ua ON ua.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
WHERE 
    fp.PopularityRank <= 10 -- Only show top 10 in each category
GROUP BY 
    fp.Title, fp.Owner, fp.Popularity, ua.UserRank
ORDER BY 
    fp.Popularity DESC, COUNT(fp.TagName) DESC;
